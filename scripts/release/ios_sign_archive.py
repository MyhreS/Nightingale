#!/usr/bin/env python3
"""Distribution-sign the app inside an unsigned Xcode archive.

Automatic archive signing needs an Apple Development certificate for the app's
team, and that team is at Apple's certificate limit, so no build machine can
get one. The release therefore archives with CODE_SIGNING_ALLOWED=NO and this
script signs the archived app with the Apple Distribution identity and its App
Store profile, carrying the project's entitlements. `xcodebuild -exportArchive`
then re-signs from these entitlements; without this step an unsigned archive
would export with none and lose the Keychain access groups Arthur and Shelby
depend on.

Stdlib only; uses `security` and `codesign`.

Usage:
    ios_sign_archive.py --app ARCHIVE/Products/Applications/X.app \\
        --profile X.mobileprovision --identity SHA1 --keychain PATH \\
        [--entitlements project.entitlements]
"""

from __future__ import annotations

import argparse
import plistlib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Keys Xcode derives from the profile for a distribution build.
PROFILE_KEYS = (
    "application-identifier",
    "com.apple.developer.team-identifier",
    "get-task-allow",
    "beta-reports-active",
)


def decode_profile(path: Path) -> dict:
    result = subprocess.run(
        ["security", "cms", "-D", "-i", str(path)], capture_output=True, check=True
    )
    return plistlib.loads(result.stdout)


def resolve(value: object, substitutions: dict[str, str]) -> object:
    if isinstance(value, str):
        for name, replacement in substitutions.items():
            value = value.replace(f"$({name})", replacement)
        if "$(" in value:
            raise ValueError(f"unresolved build setting in entitlements: {value}")
        return value
    if isinstance(value, list):
        return [resolve(item, substitutions) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item, substitutions) for key, item in value.items()}
    return value


def entitlements_for(profile: dict, bundle_id: str, project: Path | None) -> dict:
    granted = profile["Entitlements"]
    team = profile["TeamIdentifier"][0]
    if granted["application-identifier"] != f"{team}.{bundle_id}":
        raise ValueError(
            f"profile {profile['Name']!r} is for {granted['application-identifier']}, "
            f"not {team}.{bundle_id}"
        )
    result = {key: granted[key] for key in PROFILE_KEYS if key in granted}
    # Xcode's default when the project declares no Keychain groups.
    result["keychain-access-groups"] = [granted["application-identifier"]]
    if project is not None:
        with project.open("rb") as stream:
            declared = plistlib.load(stream)
        prefix = f"{team}."
        declared = resolve(
            declared,
            {
                "AppIdentifierPrefix": prefix,
                "TeamIdentifierPrefix": prefix,
                "PRODUCT_BUNDLE_IDENTIFIER": bundle_id,
            },
        )
        missing = sorted(set(declared) - set(granted))
        if missing:
            raise ValueError(f"the App Store profile does not grant: {', '.join(missing)}")
        result.update(declared)
    return result


def codesign(path: Path, identity: str, keychain: str, *extra: str) -> None:
    subprocess.run(
        ["codesign", "--force", "--sign", identity, "--keychain", keychain, *extra, str(path)],
        check=True,
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--profile", required=True, type=Path)
    parser.add_argument("--identity", required=True, help="codesigning identity SHA-1")
    parser.add_argument("--keychain", required=True)
    parser.add_argument("--entitlements", type=Path, help="the target's CODE_SIGN_ENTITLEMENTS")
    args = parser.parse_args(argv)

    try:
        with (args.app / "Info.plist").open("rb") as stream:
            bundle_id = plistlib.load(stream)["CFBundleIdentifier"]
        profile = decode_profile(args.profile)
        entitlements = entitlements_for(profile, bundle_id, args.entitlements)
        # Nested bundles would each need their own profile; none ship today.
        for nested in ("PlugIns", "Watch", "Extensions", "AppClips"):
            if (args.app / nested).exists():
                raise ValueError(f"{nested}/ is not supported by this signer")
        shutil.copyfile(args.profile, args.app / "embedded.mobileprovision")
        frameworks = args.app / "Frameworks"
        if frameworks.is_dir():
            for item in sorted(frameworks.iterdir()):
                if item.suffix in (".framework", ".dylib"):
                    codesign(item, args.identity, args.keychain)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "app.entitlements"
            path.write_bytes(plistlib.dumps(entitlements))
            codesign(args.app, args.identity, args.keychain, "--entitlements", str(path))
        subprocess.run(["codesign", "--verify", "--strict", str(args.app)], check=True)
    except (OSError, KeyError, ValueError, subprocess.CalledProcessError) as error:
        print(f"archive signing failed: {error}", file=sys.stderr)
        return 1
    print(f"Signed {bundle_id} with profile {profile['Name']!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
