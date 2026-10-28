#!/usr/bin/env bash
set -euo pipefail

# One-off: create a portable Apple Distribution identity for the team and store
# it in Doppler nightingale/prd, so ios-testflight.sh can sign on any Mac or CI.
#
#   scripts/release/setup-distribution-certificate.sh
#
# Needs an Admin-role App Store Connect API key in ASC_API_KEY_* (Apple answers
# 403 for App Manager/Developer keys). Writes APPLE_DISTRIBUTION_P12_BASE64,
# APPLE_DISTRIBUTION_P12_PASSWORD and APPLE_DISTRIBUTION_CERTIFICATE_ID; the
# private key only ever exists in a temporary directory and in Doppler.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly repo_root
# shellcheck source=scripts/release/asc-credentials.sh disable=SC1091
source "${repo_root}/scripts/release/asc-credentials.sh"

if has_release_secret APPLE_DISTRIBUTION_P12_BASE64; then
	echo "APPLE_DISTRIBUTION_P12_BASE64 already exists in Doppler ${RELEASE_DOPPLER_PROJECT}/${RELEASE_DOPPLER_CONFIG}; delete it first to replace it." >&2
	exit 1
fi

load_asc_credentials

work="$(mktemp -d)"
chmod 700 "${work}"
trap 'rm -rf "${work}"' EXIT

openssl genrsa -out "${work}/distribution.key" 2048 2>/dev/null
openssl req -new -key "${work}/distribution.key" -subj "/CN=PuckBeats Distribution/C=NO" -out "${work}/distribution.csr"

certificate_id="$(python3 "${repo_root}/scripts/release/asc_client.py" distribution-certificate \
	--csr "${work}/distribution.csr" --out "${work}/distribution.cer" \
	--key-id "${ASC_API_KEY_ID}" --issuer-id "${ASC_API_KEY_ISSUER_ID}" --key "${ASC_KEY_PATH}")"

openssl x509 -inform DER -in "${work}/distribution.cer" -out "${work}/distribution.pem"
password="$(openssl rand -hex 24)"
# 3DES/SHA1 so macOS `security import` accepts it.
openssl pkcs12 -export -inkey "${work}/distribution.key" -in "${work}/distribution.pem" \
	-out "${work}/distribution.p12" -passout "pass:${password}" \
	-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

# Prove macOS can import it and it is the expected team before storing.
security create-keychain -p check "${work}/check.keychain-db"
security import "${work}/distribution.p12" -k "${work}/check.keychain-db" -f pkcs12 -P "${password}" >/dev/null
team="$(release_secret APPLE_TEAM_ID)"
security find-identity -v -p codesigning "${work}/check.keychain-db" | grep -q "Apple Distribution: .*(${team})" || {
	security delete-keychain "${work}/check.keychain-db"
	echo "issued certificate is not an Apple Distribution identity for ${team}" >&2
	exit 1
}
security delete-keychain "${work}/check.keychain-db"

python3 - "${work}" "${password}" "${certificate_id}" <<'EOF'
import base64, json, sys
work, password, certificate_id = sys.argv[1:4]
with open(f"{work}/distribution.p12", "rb") as stream:
    bundle = base64.b64encode(stream.read()).decode()
with open(f"{work}/secrets.json", "w") as stream:
    json.dump({
        "APPLE_DISTRIBUTION_P12_BASE64": bundle,
        "APPLE_DISTRIBUTION_P12_PASSWORD": password,
        "APPLE_DISTRIBUTION_CERTIFICATE_ID": certificate_id,
    }, stream)
EOF
doppler secrets upload -p "${RELEASE_DOPPLER_PROJECT}" -c "${RELEASE_DOPPLER_CONFIG}" "${work}/secrets.json" --silent >/dev/null
echo "Stored Apple Distribution ${certificate_id} for ${team} in Doppler ${RELEASE_DOPPLER_PROJECT}/${RELEASE_DOPPLER_CONFIG}."
