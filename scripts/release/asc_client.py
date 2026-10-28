#!/usr/bin/env python3
"""Ask App Store Connect what version an app is actually on.

The release loop cannot trust `project.pbxproj` alone: a release made from
Xcode bumps the version at Apple without committing anything, so the tracked
version silently falls behind and the next patch bump computes a number Apple
has already consumed (see issue #1215).

Stdlib only. ECDSA signing is delegated to the `openssl` CLI rather than pulling
in `cryptography`, so this keeps running outside any Poetry environment.

Usage:
    asc_client.py latest-version <bundle-id> --key-id ID --issuer-id ID --key PATH
    asc_client.py app-store-profile <bundle-id> --certificate-id ID --out PATH \\
        --key-id ID --issuer-id ID --key PATH
    asc_client.py distribution-certificate --csr PATH --out PATH \\
        --key-id ID --issuer-id ID --key PATH

Copied from sonix tools/scripts/release (William's iOS release tooling).
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ASC_API = "https://api.appstoreconnect.apple.com/v1"
ASC_AUDIENCE = "appstoreconnect-v1"
TOKEN_LIFETIME_SECONDS = 600  # Apple rejects anything longer than 20 minutes.
EC_COORDINATE_BYTES = 32  # P-256: r and s are 32 bytes each.
HTTP_TIMEOUT_SECONDS = 30

# A python.org build on macOS ships no CA bundle and cannot see the system
# keychain, so HTTPS fails with CERTIFICATE_VERIFY_FAILED. Fall back to the
# OpenSSL bundle macOS installs. Verification is never disabled.
_CA_BUNDLE_FALLBACKS = (
    "/etc/ssl/cert.pem",
    "/opt/homebrew/etc/openssl@3/cert.pem",
    "/usr/local/etc/openssl@3/cert.pem",
)


class AscError(Exception):
    """App Store Connect could not be queried."""


def _b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def der_to_jose(der: bytes) -> bytes:
    """Convert an OpenSSL DER ECDSA signature to the raw r||s form JWS wants.

    DER is SEQUENCE { INTEGER r, INTEGER s } with minimal, sign-extended
    integers; JOSE wants each value zero-padded to a fixed 32 bytes.
    """
    if not der or der[0] != 0x30:
        raise AscError("signature is not a DER sequence")

    index = 2
    if der[1] & 0x80:  # long-form length
        index = 2 + (der[1] & 0x7F)

    values = []
    for _ in range(2):
        if der[index] != 0x02:
            raise AscError("signature is missing a DER integer")
        length = der[index + 1]
        value = der[index + 2 : index + 2 + length]
        index += 2 + length
        value = value.lstrip(b"\x00")
        if len(value) > EC_COORDINATE_BYTES:
            raise AscError("signature integer is too large for P-256")
        values.append(value.rjust(EC_COORDINATE_BYTES, b"\x00"))

    return values[0] + values[1]


def mint_token(key_id: str, issuer_id: str, key_path: str, *, now: int | None = None) -> str:
    """Build the ES256 JWT App Store Connect expects."""
    issued_at = int(time.time()) if now is None else now
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {
        "iss": issuer_id,
        "iat": issued_at,
        "exp": issued_at + TOKEN_LIFETIME_SECONDS,
        "aud": ASC_AUDIENCE,
    }
    signing_input = ".".join(
        _b64url(json.dumps(part, separators=(",", ":")).encode()) for part in (header, payload)
    )

    try:
        completed = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_path],
            input=signing_input.encode(),
            capture_output=True,
            check=True,
        )
    except FileNotFoundError as error:
        raise AscError("openssl is required to sign the App Store Connect token") from error
    except subprocess.CalledProcessError as error:
        detail = error.stderr.decode(errors="replace").strip()
        raise AscError(f"could not sign the token with {key_path}: {detail}") from error

    return f"{signing_input}.{_b64url(der_to_jose(completed.stdout))}"


def ssl_context() -> ssl.SSLContext:
    context = ssl.create_default_context()
    if context.get_ca_certs():
        return context
    for bundle in _CA_BUNDLE_FALLBACKS:
        if os.path.exists(bundle):
            context.load_verify_locations(bundle)
            return context
    raise AscError(
        "no CA bundle found for HTTPS verification; set SSL_CERT_FILE to one"
    )


def _get(path: str, token: str, params: dict[str, str] | None = None) -> dict:
    url = f"{ASC_API}/{path}"
    if params:
        url = f"{url}?{urllib.parse.urlencode(params)}"
    return _send(urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"}), path)


def _post(path: str, token: str, body: dict) -> dict:
    request = urllib.request.Request(
        f"{ASC_API}/{path}",
        data=json.dumps(body).encode(),
        method="POST",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    return _send(request, path)


def _send(request: urllib.request.Request, path: str) -> dict:
    try:
        with urllib.request.urlopen(
            request, timeout=HTTP_TIMEOUT_SECONDS, context=ssl_context()
        ) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="replace")[:500]
        raise AscError(f"App Store Connect returned {error.code} for {path}: {body}") from error
    except urllib.error.URLError as error:
        raise AscError(f"could not reach App Store Connect: {error.reason}") from error


def app_id(bundle_id: str, token: str) -> str:
    data = _get("apps", token, {"filter[bundleId]": bundle_id, "limit": "1"}).get("data", [])
    if not data:
        raise AscError(
            f"no app with bundle id {bundle_id} is visible to this API key "
            "(wrong team, or the key lacks App Manager access)"
        )
    return data[0]["id"]


def known_versions(bundle_id: str, token: str) -> list[str]:
    """Every version string Apple knows, across TestFlight and the App Store.

    Both are checked: a TestFlight-only build never reaches appStoreVersions,
    and an old released version may no longer have a prerelease record.
    """
    identifier = app_id(bundle_id, token)
    versions: list[str] = []
    for relationship, field in (
        ("preReleaseVersions", "version"),
        ("appStoreVersions", "versionString"),
    ):
        payload = _get(f"apps/{identifier}/{relationship}", token, {"limit": "200"})
        versions.extend(
            entry["attributes"][field]
            for entry in payload.get("data", [])
            if entry.get("attributes", {}).get(field)
        )
    return versions


def app_store_profile(bundle_id: str, certificate_id: str, token: str) -> bytes:
    """Return an active App Store profile for the bundle that embeds the certificate.

    Profiles are public signing metadata, not secrets, and expire with their
    certificate, so they are fetched from Apple at release time rather than
    stored. One is created only when no usable profile exists.
    """
    bundles = _get(
        "bundleIds",
        token,
        {"filter[identifier]": bundle_id, "filter[platform]": "IOS", "limit": "20"},
    ).get("data", [])
    # filter[identifier] is a prefix match; demand the exact bundle.
    bundle = next((b for b in bundles if b["attributes"]["identifier"] == bundle_id), None)
    if bundle is None:
        raise AscError(f"bundle id {bundle_id} is not registered for this team")
    profiles = _get(
        "profiles",
        token,
        {
            "filter[profileType]": "IOS_APP_STORE",
            "filter[profileState]": "ACTIVE",
            "include": "bundleId,certificates",
            "limit": "200",
        },
    )
    for profile in profiles.get("data", []):
        relationships = profile.get("relationships", {})
        certificates = relationships.get("certificates", {}).get("data", [])
        if relationships.get("bundleId", {}).get("data", {}).get("id") == bundle["id"] and any(
            c["id"] == certificate_id for c in certificates
        ):
            return base64.b64decode(profile["attributes"]["profileContent"])
    created = _post(
        "profiles",
        token,
        {
            "data": {
                "type": "profiles",
                "attributes": {
                    "name": f"{bundle_id} App Store {time.strftime('%Y%m%d')}",
                    "profileType": "IOS_APP_STORE",
                },
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}},
                    "certificates": {"data": [{"type": "certificates", "id": certificate_id}]},
                },
            }
        },
    )
    return base64.b64decode(created["data"]["attributes"]["profileContent"])


def create_distribution_certificate(csr: str, token: str) -> tuple[str, bytes]:
    """Have Apple issue an Apple Distribution certificate for a CSR.

    Needs an Admin-role API key; Apple answers 403 for lower roles.
    """
    created = _post(
        "certificates",
        token,
        {
            "data": {
                "type": "certificates",
                "attributes": {"certificateType": "DISTRIBUTION", "csrContent": csr},
            }
        },
    )["data"]
    return created["id"], base64.b64decode(created["attributes"]["certificateContent"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    latest = sub.add_parser("latest-version", help="print the highest version Apple knows")
    latest.add_argument("bundle_id")
    latest.add_argument("--key-id", required=True)
    latest.add_argument("--issuer-id", required=True)
    latest.add_argument("--key", required=True, help="path to the AuthKey_*.p8")
    latest.add_argument(
        "--allow-missing",
        action="store_true",
        help="print nothing and succeed when Apple cannot be reached",
    )

    profile = sub.add_parser(
        "app-store-profile", help="write an App Store provisioning profile for a bundle id"
    )
    profile.add_argument("bundle_id")
    profile.add_argument("--certificate-id", required=True)
    profile.add_argument("--out", required=True, help="where to write the .mobileprovision")
    profile.add_argument("--key-id", required=True)
    profile.add_argument("--issuer-id", required=True)
    profile.add_argument("--key", required=True, help="path to the AuthKey_*.p8")

    certificate = sub.add_parser(
        "distribution-certificate", help="issue an Apple Distribution certificate for a CSR"
    )
    certificate.add_argument("--csr", required=True, help="PEM certificate signing request")
    certificate.add_argument("--out", required=True, help="where to write the DER certificate")
    certificate.add_argument("--key-id", required=True)
    certificate.add_argument("--issuer-id", required=True)
    certificate.add_argument("--key", required=True, help="path to the AuthKey_*.p8")

    args = parser.parse_args(argv)

    if args.command == "distribution-certificate":
        try:
            token = mint_token(args.key_id, args.issuer_id, args.key)
            with open(args.csr) as stream:
                certificate_id, content = create_distribution_certificate(stream.read(), token)
        except AscError as error:
            print(f"error: {error}", file=sys.stderr)
            return 1
        with open(args.out, "wb") as stream:
            stream.write(content)
        print(certificate_id)
        return 0

    if args.command == "app-store-profile":
        try:
            token = mint_token(args.key_id, args.issuer_id, args.key)
            content = app_store_profile(args.bundle_id, args.certificate_id, token)
        except AscError as error:
            print(f"error: {error}", file=sys.stderr)
            return 1
        with open(args.out, "wb") as stream:
            stream.write(content)
        return 0

    try:
        token = mint_token(args.key_id, args.issuer_id, args.key)
        versions = known_versions(args.bundle_id, token)
    except AscError as error:
        if args.allow_missing:
            print(f"warning: {error}", file=sys.stderr)
            return 0
        print(f"error: {error}", file=sys.stderr)
        return 1

    if not versions:
        return 0  # A brand-new app with nothing uploaded yet.

    # Imported lazily so this module stays usable without the sibling script.
    from ios_version import parse_version

    parsed = []
    for version in versions:
        try:
            parsed.append(parse_version(version))
        except Exception:  # noqa: BLE001 - Apple allows strings we don't model
            continue
    if parsed:
        print(max(parsed, key=lambda version: version.as_tuple()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
