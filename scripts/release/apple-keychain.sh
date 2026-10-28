# shellcheck shell=bash
# Temporary signing keychain for the Apple release scripts. Sourced, not run,
# after scripts/release/asc-credentials.sh (for release_secret).
#
# A release imports its certificates into a throwaway keychain, never the login
# keychain, so a local run leaves the operator's Mac as it found it and a CI
# run leaves nothing behind for the next job.
#
# apple_keychain_open <private-dir>
#   Creates <private-dir>/release.keychain-db with a random password, unlocks
#   it, and prepends it to the user search list (codesign calls that do not
#   pass --keychain, such as Curly's servicing/build.sh, must still find it).
#   Sets APPLE_KEYCHAIN. Callers must run apple_keychain_close on every exit.
# apple_keychain_import <P12_BASE64_SECRET> <P12_PASSWORD_SECRET>
#   Imports one base64 .p12 bundle by secret name; the decoded file is deleted
#   immediately. Call apple_keychain_allow once after the last import.
# apple_keychain_identity <prefix> <team>
#   Prints "<SHA-1><TAB><name>" of the single valid identity whose name starts
#   with <prefix> and ends with "(<team>)".
# apple_keychain_close
#   Restores the search list and deletes the keychain. Safe to call twice.

apple_keychain_open() {
	APPLE_KEYCHAIN="$1/release.keychain-db"
	APPLE_KEYCHAIN_PASSWORD="$(openssl rand -hex 32)"
	# Read once; `security list-keychains` prints quoted, indented paths.
	APPLE_KEYCHAIN_SEARCH=()
	local entry
	while IFS= read -r entry; do
		entry="${entry#"${entry%%[![:space:]]*}"}"
		entry="${entry#\"}"
		entry="${entry%\"}"
		[[ -n "${entry}" ]] && APPLE_KEYCHAIN_SEARCH+=("${entry}")
	done < <(security list-keychains -d user)
	security create-keychain -p "${APPLE_KEYCHAIN_PASSWORD}" "${APPLE_KEYCHAIN}"
	# No auto-lock during a long notarization wait (seconds).
	security set-keychain-settings -lut 21600 "${APPLE_KEYCHAIN}"
	security unlock-keychain -p "${APPLE_KEYCHAIN_PASSWORD}" "${APPLE_KEYCHAIN}"
	security list-keychains -d user -s "${APPLE_KEYCHAIN}" "${APPLE_KEYCHAIN_SEARCH[@]}"
	export APPLE_KEYCHAIN
}

apple_keychain_import() {
	local bundle
	bundle="$(mktemp "$(dirname "${APPLE_KEYCHAIN}")/identity.XXXXXX")"
	if ! release_secret "$1" | base64 --decode >"${bundle}"; then
		rm -f "${bundle}"
		echo "could not decode $1" >&2
		return 1
	fi
	# -T grants these tools use of the private key without a GUI prompt.
	if ! security import "${bundle}" -k "${APPLE_KEYCHAIN}" -f pkcs12 \
		-P "$(release_secret "$2")" \
		-T /usr/bin/codesign -T /usr/bin/productbuild -T /usr/bin/productsign \
		-T /usr/bin/security >/dev/null; then
		rm -f "${bundle}"
		echo "could not import $1 into the release keychain" >&2
		return 1
	fi
	rm -f "${bundle}"
}

apple_keychain_allow() {
	# Without the partition list a locked-down key makes codesign (and
	# -exportArchive) hang on an invisible approval prompt.
	security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
		-k "${APPLE_KEYCHAIN_PASSWORD}" "${APPLE_KEYCHAIN}" >/dev/null
}

apple_keychain_identity() {
	# Callers commonly hold readonly `team`/`prefix`; never shadow them.
	local identity_prefix="$1" identity_team="$2" matches
	# The default (basic) policy lists installer identities too.
	matches="$(security find-identity -v "${APPLE_KEYCHAIN}" |
		awk -v prefix="\"${identity_prefix}" -v suffix="(${identity_team})\"" '
			index($0, prefix) && index($0, suffix) {
				name = substr($0, index($0, "\"") + 1)
				print $2 "\t" substr(name, 1, length(name) - 1)
			}')"
	[[ -n "${matches}" && "$(wc -l <<<"${matches}")" -eq 1 ]] || {
		echo "expected exactly one '${identity_prefix}... (${identity_team})' identity in the release keychain" >&2
		return 1
	}
	printf '%s' "${matches}"
}

apple_keychain_close() {
	[[ -n "${APPLE_KEYCHAIN:-}" ]] || return 0
	security list-keychains -d user -s "${APPLE_KEYCHAIN_SEARCH[@]}" || true
	security delete-keychain "${APPLE_KEYCHAIN}" 2>/dev/null || true
	APPLE_KEYCHAIN=""
}
