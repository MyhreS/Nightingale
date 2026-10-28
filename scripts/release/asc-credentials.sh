# shellcheck shell=bash
# App Store Connect credential loading for the release scripts. Sourced, not run.
# Adapted from sonix tools/scripts/release/asc-credentials.sh.
#
# release_secret NAME
#   Prints one secret. A non-empty environment variable of the same name wins
#   (GitHub Actions injects synced copies that way); otherwise it is read from
#   Doppler project `nightingale`, config `prd`. Doppler is the source of truth.
# has_release_secret NAME
#   Succeeds when NAME is set in the environment or exists in Doppler.
# load_asc_credentials
#   Exports ASC_API_KEY_ID and ASC_API_KEY_ISSUER_ID, writes the private key to
#   ~/private_keys/AuthKey_<id>.p8 (where xcodebuild and altool look for it),
#   and sets ASC_KEY_PATH to it. The decoded key never appears in the log.

RELEASE_DOPPLER_PROJECT="${NIGHTINGALE_DOPPLER_PROJECT:-nightingale}"
RELEASE_DOPPLER_CONFIG="${NIGHTINGALE_DOPPLER_CONFIG:-prd}"

release_secret() {
	local name="$1" value
	if [[ -n "${!name:-}" ]]; then
		printf '%s' "${!name}"
		return
	fi
	command -v doppler >/dev/null || {
		echo "${name} is not set and doppler is not installed" >&2
		exit 1
	}
	value="$(doppler secrets get "${name}" -p "${RELEASE_DOPPLER_PROJECT}" -c "${RELEASE_DOPPLER_CONFIG}" --plain)"
	[[ -n "${value}" ]] || {
		echo "${name} is empty in Doppler ${RELEASE_DOPPLER_PROJECT}/${RELEASE_DOPPLER_CONFIG}" >&2
		exit 1
	}
	printf '%s' "${value}"
}

has_release_secret() {
	local name="$1"
	[[ -n "${!name:-}" ]] && return 0
	command -v doppler >/dev/null || return 1
	doppler secrets -p "${RELEASE_DOPPLER_PROJECT}" -c "${RELEASE_DOPPLER_CONFIG}" --only-names --json 2>/dev/null |
		python3 -c 'import json, sys; sys.exit(0 if sys.argv[1] in json.load(sys.stdin) else 1)' "${name}"
}

load_asc_credentials() {
	ASC_API_KEY_ID="$(release_secret ASC_API_KEY_ID)" || return 1
	ASC_API_KEY_ISSUER_ID="$(release_secret ASC_API_KEY_ISSUER_ID)" || return 1
	export ASC_API_KEY_ID ASC_API_KEY_ISSUER_ID

	local key_dir="${HOME}/private_keys"
	ASC_KEY_PATH="${key_dir}/AuthKey_${ASC_API_KEY_ID}.p8"
	export ASC_KEY_PATH

	mkdir -p "${key_dir}"
	chmod 700 "${key_dir}"
	local encoded temporary
	encoded="$(release_secret ASC_API_KEY_P8)" || return 1
	temporary="$(mktemp "${key_dir}/.asc-key.XXXXXX")" || return 1
	if ! printf '%s' "${encoded}" | base64 --decode >"${temporary}"; then
		rm -f "${temporary}"
		return 1
	fi
	if ! openssl pkey -in "${temporary}" -noout >/dev/null 2>&1; then
		rm -f "${temporary}"
		echo "Doppler ASC key is not a valid private key" >&2
		return 1
	fi
	chmod 600 "${temporary}"
	mv -f "${temporary}" "${ASC_KEY_PATH}"
}
