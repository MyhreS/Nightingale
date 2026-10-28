#!/usr/bin/env bash
set -euo pipefail

# Archive PuckBeats (Nightingale) as Release, sign it for the App Store and
# upload it to TestFlight. Adapted from sonix tools/scripts/release/ios-testflight.sh.
#
#   scripts/release/ios-testflight.sh                  # upload
#   scripts/release/ios-testflight.sh --validate-only  # sign + let Apple validate, no delivery
#   scripts/release/ios-testflight.sh --no-upload      # sign + export a local .ipa
#   scripts/release/ios-testflight.sh --original        # ship to the App Store app instead
#
# By default builds go to the TestFlight-only app "Hockey Secretary Music"
# (sm.puckbeats). --original ships the project's own sm.Nightingale / PuckBeats
# (the App Store app); --bundle-id/--name target any other existing app record.
#
# Signing, chosen automatically:
#   portable  APPLE_DISTRIBUTION_P12_* is in Doppler: archive unsigned, sign with
#             that identity from a temporary keychain and an App Store profile
#             fetched from Apple. Works on any Mac and in CI.
#   xcode     otherwise: Xcode's automatic signing with the Apple ID signed in to
#             Xcode on this Mac (cloud-managed Apple Distribution certificate).
#             Create a portable identity with setup-distribution-certificate.sh.
# Force one with NIGHTINGALE_SIGNING=portable|xcode.
#
# Secrets (environment first, else Doppler nightingale/prd):
#   ASC_API_KEY_ID, ASC_API_KEY_ISSUER_ID, ASC_API_KEY_P8, APPLE_TEAM_ID
#   APPLE_DISTRIBUTION_P12_BASE64, _P12_PASSWORD, _CERTIFICATE_ID (portable only)
#
# Build number = commit count (monotonic on main). Marketing version comes from
# the project; bump MARKETING_VERSION once a version has been released.
#
# Exit codes: 0 delivered (or exported/validated), 1 failure, 75 App Store
# Connect already has this version/build (bump MARKETING_VERSION and rerun).

readonly EXIT_VERSION_CONFLICT=75

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
readonly project_dir="${repo_root}/Nightingale"
readonly project="Nightingale.xcodeproj"
readonly scheme="Nightingale"
readonly target="Nightingale"

usage() {
	echo "usage: ios-testflight.sh [--allow-stale] [--no-upload | --validate-only] [--original | --bundle-id ID [--name NAME]]" >&2
	exit 1
}

allow_stale=0
mode=upload
# Only the app target reads these (see PRODUCT_BUNDLE_IDENTIFIER in the project),
# so package targets keep their own bundle identifiers.
variant_bundle_id=sm.puckbeats
variant_name="Hockey Secretary Music"
while (($# > 0)); do
	case "$1" in
	--allow-stale) allow_stale=1 ;;
	--original)
		variant_bundle_id=""
		variant_name=""
		;;
	--bundle-id)
		[[ $# -ge 2 ]] || usage
		variant_bundle_id="$2"
		variant_name=""
		shift
		;;
	--name)
		[[ $# -ge 2 ]] || usage
		variant_name="$2"
		shift
		;;
	--no-upload) mode='export' ;;
	--validate-only) mode=validate ;;
	*) usage ;;
	esac
	shift
done

variant_settings=()
[[ -n "${variant_bundle_id}" ]] && variant_settings+=("NIGHTINGALE_BUNDLE_ID=${variant_bundle_id}")
[[ -n "${variant_name}" ]] && variant_settings+=("NIGHTINGALE_APP_NAME=${variant_name}")
readonly variant_settings

# Refuse to ship a tree that is not exactly origin/main: a build from other code
# burns a build number that can never be reused for this version.
if ((!allow_stale)); then
	git -C "${repo_root}" fetch --quiet origin main
	[[ -z "$(git -C "${repo_root}" status --porcelain)" ]] || {
		echo "working tree has uncommitted changes (use --allow-stale to ship anyway)" >&2
		exit 1
	}
	[[ "$(git -C "${repo_root}" rev-parse HEAD)" == "$(git -C "${repo_root}" rev-parse origin/main)" ]] || {
		echo "HEAD is not origin/main (use --allow-stale to ship anyway)" >&2
		exit 1
	}
fi

# shellcheck source=scripts/release/asc-credentials.sh disable=SC1091
source "${repo_root}/scripts/release/asc-credentials.sh"
# shellcheck source=scripts/release/apple-keychain.sh disable=SC1091
source "${repo_root}/scripts/release/apple-keychain.sh"
load_asc_credentials

# The SoundCloud build settings live in a gitignored xcconfig; a fresh checkout
# (CI, another Mac) gets it from Doppler. An existing local copy is left alone.
readonly secrets_xcconfig="${project_dir}/Secrets.xcconfig"
if [[ ! -f "${secrets_xcconfig}" ]]; then
	{
		echo "SOUND_CLOUD_CLIENT_ID = $(release_secret IOS_SOUND_CLOUD_CLIENT_ID)"
		echo "SOUND_CLOUD_CLIENT_SECRET = $(release_secret IOS_SOUND_CLOUD_CLIENT_SECRET)"
		echo "REDIRECT_URI = $(release_secret IOS_REDIRECT_URI)"
	} >"${secrets_xcconfig}"
	chmod 600 "${secrets_xcconfig}"
fi

signing="${NIGHTINGALE_SIGNING:-}"
if [[ -z "${signing}" ]]; then
	if has_release_secret APPLE_DISTRIBUTION_P12_BASE64; then signing=portable; else signing=xcode; fi
fi
[[ "${signing}" == portable || "${signing}" == xcode ]] || usage
readonly signing

build_number="${NIGHTINGALE_IOS_BUILD_NUMBER:-}"
if [[ -z "${build_number}" ]]; then
	[[ "$(git -C "${repo_root}" rev-parse --is-shallow-repository)" == false ]] || {
		echo "shallow checkout: the commit-count build number would be wrong" >&2
		exit 1
	}
	build_number="$(git -C "${repo_root}" rev-list --count HEAD)"
fi
readonly build_number

work_dir="$(mktemp -d)"
chmod 700 "${work_dir}"
readonly work_dir
installed_profiles=()

cleanup() {
	apple_keychain_close
	local installed
	for installed in "${installed_profiles[@]+"${installed_profiles[@]}"}"; do
		rm -f "${installed}"
	done
	if [[ "${mode}" == export ]]; then
		find "${work_dir}" -mindepth 1 -maxdepth 1 ! -name export -exec rm -rf {} +
	else
		rm -rf "${work_dir}"
	fi
}
trap cleanup EXIT

readonly archive_path="${work_dir}/Nightingale.xcarchive"
readonly log_path="${work_dir}/altool.log"

cd "${project_dir}"

settings="$(xcodebuild -showBuildSettings -json -project "${project}" -scheme "${scheme}" \
	-configuration Release -sdk iphoneos "${variant_settings[@]+"${variant_settings[@]}"}" 2>/dev/null |
	python3 -c '
import json, sys
entry = next(e for e in json.load(sys.stdin) if e["target"] == sys.argv[1])["buildSettings"]
print(entry["PRODUCT_BUNDLE_IDENTIFIER"], entry["DEVELOPMENT_TEAM"], entry["MARKETING_VERSION"],
      entry.get("CODE_SIGN_ENTITLEMENTS", ""), sep="\t")
' "${target}")"
IFS=$'\t' read -r bundle_id team marketing_version entitlements <<<"${settings}"
readonly bundle_id team marketing_version entitlements
[[ "${team}" == "$(release_secret APPLE_TEAM_ID)" ]] || {
	echo "project team ${team} does not match APPLE_TEAM_ID in Doppler" >&2
	exit 1
}

echo "Releasing ${bundle_id} ${marketing_version} (build ${build_number}) from $(git -C "${repo_root}" rev-parse --short HEAD) [${signing} signing]"

xcodebuild -resolvePackageDependencies -project "${project}" -scheme "${scheme}" \
	-onlyUsePackageVersionsFromResolvedFile >"${work_dir}/resolve.log" 2>&1 || {
	cat "${work_dir}/resolve.log" >&2
	echo "Swift package resolution failed" >&2
	exit 1
}

if [[ "${signing}" == portable ]]; then
	apple_keychain_open "${work_dir}"
	apple_keychain_import APPLE_DISTRIBUTION_P12_BASE64 APPLE_DISTRIBUTION_P12_PASSWORD
	apple_keychain_allow
	identity="$(apple_keychain_identity "Apple Distribution: " "${team}" | cut -f1)"

	profile="${work_dir}/app-store.mobileprovision"
	python3 "${repo_root}/scripts/release/asc_client.py" app-store-profile "${bundle_id}" \
		--certificate-id "$(release_secret APPLE_DISTRIBUTION_CERTIFICATE_ID)" --out "${profile}" \
		--key-id "${ASC_API_KEY_ID}" --issuer-id "${ASC_API_KEY_ISSUER_ID}" --key "${ASC_KEY_PATH}"
	profile_uuid="$(security cms -D -i "${profile}" | plutil -extract UUID raw -o - -)"
	for directory in "${HOME}/Library/Developer/Xcode/UserData/Provisioning Profiles" \
		"${HOME}/Library/MobileDevice/Provisioning Profiles"; do
		mkdir -p "${directory}"
		if [[ ! -e "${directory}/${profile_uuid}.mobileprovision" ]]; then
			cp "${profile}" "${directory}/${profile_uuid}.mobileprovision"
			installed_profiles+=("${directory}/${profile_uuid}.mobileprovision")
		fi
	done

	xcodebuild archive -project "${project}" -scheme "${scheme}" -configuration Release \
		-destination 'generic/platform=iOS' -archivePath "${archive_path}" \
		-onlyUsePackageVersionsFromResolvedFile -skipPackagePluginValidation -skipMacroValidation \
		CODE_SIGNING_ALLOWED=NO AppIdentifierPrefix="${team}." TeamIdentifierPrefix="${team}." \
		CURRENT_PROJECT_VERSION="${build_number}" "${variant_settings[@]+"${variant_settings[@]}"}"

	archived_app="$(find "${archive_path}/Products/Applications" -maxdepth 1 -name '*.app' -print -quit)"
	python3 "${repo_root}/scripts/release/ios_sign_archive.py" \
		--app "${archived_app}" --profile "${profile}" \
		--identity "${identity}" --keychain "${APPLE_KEYCHAIN}" \
		${entitlements:+--entitlements "${project_dir}/${entitlements}"}

	export_signing="<key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>${identity}</string>
  <key>provisioningProfiles</key><dict><key>${bundle_id}</key><string>${profile_uuid}</string></dict>"
	provisioning_args=()
else
	# Xcode's signed-in account creates/fetches the development and cloud-managed
	# distribution signing assets; the ASC key alone cannot (it is not Admin).
	xcodebuild archive -project "${project}" -scheme "${scheme}" -configuration Release \
		-destination 'generic/platform=iOS' -archivePath "${archive_path}" \
		-onlyUsePackageVersionsFromResolvedFile -allowProvisioningUpdates \
		CURRENT_PROJECT_VERSION="${build_number}" "${variant_settings[@]+"${variant_settings[@]}"}"
	export_signing="<key>signingStyle</key><string>automatic</string>"
	provisioning_args=(-allowProvisioningUpdates)
fi

cat >"${work_dir}/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>teamID</key><string>${team}</string>
  ${export_signing}
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
EOF

# Export locally and upload with altool: `-exportArchive` with destination=upload
# can exit 0 without delivering anything.
xcodebuild -exportArchive -archivePath "${archive_path}" \
	-exportOptionsPlist "${work_dir}/ExportOptions.plist" -exportPath "${work_dir}/export" \
	"${provisioning_args[@]+"${provisioning_args[@]}"}"

ipa="$(find "${work_dir}/export" -maxdepth 1 -name '*.ipa' -print -quit)"
[[ -n "${ipa}" ]] || {
	echo "export produced no .ipa in ${work_dir}/export" >&2
	exit 1
}

ditto -x -k "${ipa}" "${work_dir}/verified-export"
exported_app="$(find "${work_dir}/verified-export/Payload" -maxdepth 1 -name '*.app' -print -quit)"
codesign --verify --strict "${exported_app}"
signature="$(codesign -dvv "${exported_app}" 2>&1)"
if ! grep -q '^Authority=Apple Distribution' <<<"${signature}" ||
	! grep -qx "TeamIdentifier=${team}" <<<"${signature}"; then
	echo "exported app is not Apple Distribution-signed for ${team}" >&2
	exit 1
fi
rm -rf "${work_dir}/verified-export"

if [[ "${mode}" == export ]]; then
	echo "Exported (not uploaded): ${ipa}"
	exit 0
fi

conflict() {
	grep -qiE 'must be higher than the previously uploaded|has already been used|redundant binary upload|closed for new build submissions' "${log_path}"
}

set +e
xcrun altool --validate-app --type ios --file "${ipa}" \
	--apiKey "${ASC_API_KEY_ID}" --apiIssuer "${ASC_API_KEY_ISSUER_ID}" 2>&1 | tee "${log_path}"
validate_status="${PIPESTATUS[0]}"
set -e
if ((validate_status != 0)); then
	if conflict; then
		echo "App Store Connect already has ${marketing_version} build ${build_number}, or ${marketing_version} is closed. Bump MARKETING_VERSION." >&2
		exit "${EXIT_VERSION_CONFLICT}"
	fi
	echo "Apple rejected the build during validation — read the log above." >&2
	exit 1
fi

if [[ "${mode}" == validate ]]; then
	echo "Validated (not uploaded): ${bundle_id} ${marketing_version} (build ${build_number})."
	exit 0
fi

set +e
xcrun altool --upload-app --type ios --file "${ipa}" \
	--apiKey "${ASC_API_KEY_ID}" --apiIssuer "${ASC_API_KEY_ISSUER_ID}" 2>&1 | tee "${log_path}"
upload_status="${PIPESTATUS[0]}"
set -e
if ((upload_status != 0)); then
	if conflict; then
		echo "App Store Connect already has ${marketing_version} build ${build_number}." >&2
		exit "${EXIT_VERSION_CONFLICT}"
	fi
	echo "Upload failed — read the log above." >&2
	exit 1
fi
grep -qiE 'UPLOAD SUCCEEDED|No errors uploading' "${log_path}" || {
	echo "altool exited 0 but never confirmed delivery — treat this as NOT shipped." >&2
	exit 1
}

echo "Delivered ${bundle_id} ${marketing_version} (build ${build_number}) to TestFlight."
echo "It appears in App Store Connect once Apple finishes processing."
