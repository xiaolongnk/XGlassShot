#!/usr/bin/env python3
"""
asc-verify-build.py — Post-upload TestFlight build verification.

Polls App Store Connect until the latest build (or a specific version) is:
  1. processingState = VALID
  2. usesNonExemptEncryption != None  (patches to False if still None)
  3. internalBuildState = IN_BETA_TESTING  (actually distributable to testers)

Usage:
  python3 script/asc-verify-build.py <app_id> [build_version]

  app_id        — App Store Connect numeric app ID (e.g. 6757980673)
  build_version — CFBundleVersion string to verify (e.g. "13"). Defaults to
                  the latest uploaded build.

Credentials: reads ~/.fastlane/api_key.json
  { "key_id": "...", "issuer_id": "...", "key": "<PEM>" }

Exit codes:
  0 — build is distributable
  1 — timed out or unrecoverable error
"""

import json, sys, time, urllib.request, urllib.error
from pathlib import Path

try:
    import jwt as pyjwt
except ImportError:
    sys.exit("pip install pyjwt cryptography")

API_KEY_PATH = Path.home() / ".fastlane" / "api_key.json"
BASE = "https://api.appstoreconnect.apple.com/v1"
POLL_INTERVAL = 30   # seconds between polls
POLL_TIMEOUT  = 1800 # 30 minutes max


def make_token(data: dict) -> str:
    now = int(time.time())
    return pyjwt.encode(
        {"iss": data["issuer_id"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        data["key"], algorithm="ES256", headers={"kid": data["key_id"]}
    )


def get(url: str, token: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def patch(url: str, token: str, body: dict) -> dict:
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        url, data=data, method="PATCH",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read()) if r.length else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"PATCH {url} → HTTP {e.code}: {e.read().decode()[:200]}")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)

    app_id        = sys.argv[1]
    target_version = sys.argv[2] if len(sys.argv) > 2 else None

    key_data = json.loads(API_KEY_PATH.read_text())

    deadline = time.time() + POLL_TIMEOUT
    print(f"[asc-verify] app={app_id}  target_version={target_version or 'latest'}")

    while time.time() < deadline:
        token = make_token(key_data)  # refresh before every poll (1200s TTL)

        # Fetch recent builds
        builds = get(
            f"{BASE}/builds?filter[app]={app_id}&sort=-uploadedDate&limit=5"
            f"&fields[builds]=version,processingState,usesNonExemptEncryption,uploadedDate",
            token
        )["data"]

        if not builds:
            print("[asc-verify] No builds found yet — waiting...")
            time.sleep(POLL_INTERVAL)
            continue

        # Pick target build
        if target_version:
            build = next((b for b in builds if b["attributes"]["version"] == target_version), None)
            if not build:
                print(f"[asc-verify] Build {target_version} not visible yet — waiting...")
                time.sleep(POLL_INTERVAL)
                continue
        else:
            build = builds[0]

        build_id = build["id"]
        attrs    = build["attributes"]
        state    = attrs["processingState"]
        enc      = attrs["usesNonExemptEncryption"]
        version  = attrs["version"]

        print(f"[asc-verify] build={version}  id={build_id}  state={state}  encryption={enc}")

        # ── Step 1: wait for VALID ──────────────────────────────────────────
        if state == "PROCESSING":
            print(f"  → still processing, retry in {POLL_INTERVAL}s")
            time.sleep(POLL_INTERVAL)
            continue

        if state in ("INVALID", "PROCESSING_EXCEPTION"):
            sys.exit(f"[asc-verify] ❌ Build reached terminal error state: {state}")

        # ── Step 2: resolve export compliance if missing ────────────────────
        if enc is None:
            print("  → usesNonExemptEncryption=null — patching to false...")
            patch(
                f"{BASE}/builds/{build_id}",
                token,
                {"data": {"type": "builds", "id": build_id,
                           "attributes": {"usesNonExemptEncryption": False}}}
            )
            print("  → patched, waiting for ASC to process...")
            time.sleep(15)
            continue  # re-poll to confirm

        # ── Step 3: confirm internalBuildState = IN_BETA_TESTING ───────────
        detail = get(f"{BASE}/builds/{build_id}/buildBetaDetail", token)["data"]
        internal_state = detail["attributes"]["internalBuildState"]
        print(f"  → internalBuildState={internal_state}")

        if internal_state == "IN_BETA_TESTING":
            print(f"\n[asc-verify] ✅ Build {version} is distributable to testers.")
            return

        if internal_state == "MISSING_EXPORT_COMPLIANCE":
            print("  → MISSING_EXPORT_COMPLIANCE on betaDetail — patching again...")
            patch(
                f"{BASE}/builds/{build_id}",
                token,
                {"data": {"type": "builds", "id": build_id,
                           "attributes": {"usesNonExemptEncryption": False}}}
            )
            time.sleep(15)
            continue

        if internal_state in ("EXPIRED", "PROCESSING_EXCEPTION"):
            sys.exit(f"[asc-verify] ❌ Terminal state on beta detail: {internal_state}")

        print(f"  → waiting for IN_BETA_TESTING (currently {internal_state}), retry in {POLL_INTERVAL}s")
        time.sleep(POLL_INTERVAL)

    sys.exit(f"[asc-verify] ❌ Timed out after {POLL_TIMEOUT}s waiting for build to become distributable.")


if __name__ == "__main__":
    main()
