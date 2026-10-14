#!/usr/bin/env python3
"""
Infortts Hugging Face CDN Uploader for Jenkins CI/CD.
Uploads built APK binaries, OTA patches, and manifests directly to Hugging Face Dataset CDN (rttss/ota-patches).
Guarantees 0 bytes static binary accumulation on VPS infrastructure.

IMPORTANT: The manifest always reflects the canonical BASE RELEASE version (e.g. 2.08.00),
never an OTA-patched version. OTA patches are tracked separately via --latest-patch.
This prevents false "update available" prompts in apps that have already applied OTA patches.
"""

import os
import sys
import json
import time
import hashlib
import argparse

def get_token(custom_token=None):
    if custom_token:
        return custom_token
    if os.environ.get("HF_TOKEN"):
        return os.environ["HF_TOKEN"]
    if os.environ.get("HUGGING_FACE_HUB_TOKEN"):
        return os.environ["HUGGING_FACE_HUB_TOKEN"]
    
    # Check standard local cache files
    paths = [
        os.path.expanduser("~/.cache/huggingface/token"),
        os.path.expanduser("~/.huggingface/token"),
        os.path.expanduser("~/.config/huggingface/token")
    ]
    for p in paths:
        if os.path.exists(p):
            with open(p, "r") as f:
                t = f.read().strip()
                if t:
                    return t
    return None

def sha256_file(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()

def parse_base_version(version_str):
    """
    Derive canonical base release version and build number.
    Input: e.g. "2.08.01+20801" or "2.08.00" or "2.4.0"
    Returns (base_version_str, base_build_int)
    e.g. ("2.08.00", 20800) or ("2.04.00", 20400)
    """
    clean = version_str.split("+")[0].strip()
    parts = clean.split(".")
    if len(parts) >= 3:
        epoch = parts[0]
        major = parts[1].zfill(2)
        # Base release always has minor = 00
        base_version = f"{epoch}.{major}.00"
        try:
            build = int(f"{epoch}{major}00")
        except ValueError:
            build = 0
        return base_version, build
    return clean, 0

def main():
    parser = argparse.ArgumentParser(description="Upload APKs and OTA patches to Hugging Face CDN.")
    parser.add_argument("--slug", required=True, help="App slug name (e.g. waptia, mitochondria)")
    parser.add_argument("--apk", help="Path to built release APK file")
    parser.add_argument("--patch", help="Path to OTA differential patch file")
    parser.add_argument("--version", default="1.0.0", help="Version name (e.g. 1.2.0 or 2.03.01+20301)")
    parser.add_argument("--version-code", type=int, default=1, help="Android Version code")
    parser.add_argument("--latest-patch", type=int, default=0,
                        help="OTA patch number to embed in manifest (0 = base release, no patches yet)")
    parser.add_argument("--track", default="internal", help="Distribution track (internal, alpha, beta, production)")
    parser.add_argument("--repo", default="rttss/ota-patches", help="Hugging Face Dataset repo ID")
    parser.add_argument("--token", help="Hugging Face write token")

    args = parser.parse_args()
    token = get_token(args.token)

    if not token:
        print("[ERROR] No Hugging Face authentication token found in environment or credentials cache.", file=sys.stderr)
        sys.exit(1)

    try:
        from huggingface_hub import HfApi, create_repo
    except ImportError:
        print("[INFO] Installing huggingface_hub...")
        os.system(f"{sys.executable} -m pip install -q huggingface_hub")
        from huggingface_hub import HfApi, create_repo

    api = HfApi(token=token)
    repo_id = args.repo

    # Ensure dataset repo exists
    try:
        create_repo(repo_id=repo_id, repo_type="dataset", token=token, exist_ok=True)
    except Exception as e:
        print(f"[WARN] Repository check: {e}")

    slug = args.slug.strip().lower()

    # Compute canonical base release version — NEVER use OTA-patched version in manifest.
    # OTA patches increment the minor segment; the manifest must always reflect the base
    # release so that Waptia/apps with OTA patches installed don't see a false "update available".
    base_version, base_build = parse_base_version(args.version)

    # If --version-code was explicitly provided and looks like a proper build number, use it
    # as the latestBuild. Otherwise derive it from base_version.
    latest_build = base_build if args.version_code == 1 else args.version_code
    # Clamp to base (strip OTA patch increment from build code)
    if latest_build > 0:
        build_str = str(latest_build)
        if len(build_str) == 5:  # e.g. 20801 -> base is 20800
            latest_build = int(build_str[:4] + "00")

    latest_patch = args.latest_patch

    manifest = {
        "slug": slug,
        "package_name": f"com.infortts.{slug}",
        # Canonical release version — base only, no OTA patch suffix
        "version": base_version,
        "version_name": f"{base_version}+{latest_build}",
        "version_code": latest_build,
        "latestBuild": latest_build,
        "latestPatch": latest_patch,
        "track": args.track,
        "apk_url": f"https://huggingface.co/datasets/{repo_id}/resolve/main/{slug}/{slug}.apk",
        "updated_at": int(time.time()),
        "timestamp_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    }

    # 1. Upload APK if provided
    if args.apk and os.path.exists(args.apk):
        apk_size = os.path.getsize(args.apk)
        apk_hash = sha256_file(args.apk)
        manifest["size_bytes"] = apk_size
        manifest["sha256"] = apk_hash

        print(f"[HF CDN] Uploading {slug}.apk ({apk_size / (1024*1024):.2f} MB, SHA256: {apk_hash[:12]}...)")
        api.upload_file(
            path_or_fileobj=args.apk,
            path_in_repo=f"{slug}/{slug}.apk",
            repo_id=repo_id,
            repo_type="dataset",
            commit_message=f"CI: Release APK {slug} v{base_version} [{args.track}]"
        )
        print(f"[HF CDN] APK Live CDN: https://huggingface.co/datasets/{repo_id}/resolve/main/{slug}/{slug}.apk")

    # 2. Upload Patch if provided
    if args.patch and os.path.exists(args.patch):
        patch_name = os.path.basename(args.patch)
        patch_size = os.path.getsize(args.patch)
        patch_hash = sha256_file(args.patch)
        manifest["patch"] = {
            "filename": patch_name,
            "size_bytes": patch_size,
            "sha256": patch_hash,
            "url": f"https://huggingface.co/datasets/{repo_id}/resolve/main/{slug}/patches/{patch_name}"
        }
        print(f"[HF CDN] Uploading patch {patch_name} ({patch_size / 1024:.2f} KB)...")
        api.upload_file(
            path_or_fileobj=args.patch,
            path_in_repo=f"{slug}/patches/{patch_name}",
            repo_id=repo_id,
            repo_type="dataset",
            commit_message=f"CI: OTA Patch {slug} v{base_version} patch#{latest_patch}"
        )

    # 3. Upload Manifest
    manifest_bytes = json.dumps(manifest, indent=2).encode("utf-8")
    api.upload_file(
        path_or_fileobj=manifest_bytes,
        path_in_repo=f"{slug}/manifest.json",
        repo_id=repo_id,
        repo_type="dataset",
        commit_message=f"CI: Update manifest for {slug} v{base_version} (latestBuild={latest_build}, latestPatch={latest_patch})"
    )
    print(f"[HF CDN] Manifest Live: https://huggingface.co/datasets/{repo_id}/raw/main/{slug}/manifest.json")
    print(json.dumps(manifest, indent=2))

if __name__ == "__main__":
    main()
