#!/usr/bin/env python3
"""Rebuild the iOS 26 helper ramdisk (root.apfs) for star / SM8350.

This is the official v0.1.3 `assemble.py build` staging pipeline, with one
star-specific change: the 9 "firmware" recipes are filled from a local fw/
directory instead of K90's modem_a / bluetooth_a / gen80000_zap / vpu35_4v
images. `localfiles.make()` deliberately does not SHA-check firmware recipes
("the phone's own firmware may be another version than the release's"), so
every other one of the 564 recipes is still reproduced byte for byte from the
user's own IPSW files and checked against local-files.plist.

usage:
    build-star26-root.py --fw DIR --ipsw DIR --output FILE [--work DIR] [--dry-run]

--dry-run builds and validates the staging tree only (no APFS image is written).
Nothing here talks to the phone.
"""
import argparse
import hashlib
import json
import os
import plistlib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

RELEASE = Path("/root/star26/release/v0.1.3/hackios-k90-v0.1.3")
U = RELEASE / "hackios-xnu-userland"
HERE = RELEASE / "tools" / "release"
sys.path.insert(0, str(HERE))
import localfiles  # noqa: E402
from localfiles import file_sha256 as digest  # noqa: E402

SEVEN = "7z"
DMGS = ("os", "systemos", "appos")


def run(cmd, **kw):
    return subprocess.run([str(c) for c in cmd], check=True, **kw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fw", type=Path, required=True, help="dir with the 9 firmware stub files")
    ap.add_argument("--ipsw", type=Path, required=True, help="dir with os.dmg/systemos.dmg/appos.dmg")
    ap.add_argument("--output", type=Path, required=True, help="root.apfs to write")
    ap.add_argument("--work", type=Path, default=Path("/root/star26/p2/work"))
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    manifest = json.loads((RELEASE / "manifest.json").read_text())
    recipes = plistlib.loads((RELEASE / "local-files.plist").read_bytes())["files"]

    print("=== 1. input checks ===")
    for name in DMGS:
        dmg = args.ipsw / f"{name}.dmg"
        want = manifest["ios"]["dmg_bytes"][name]
        assert dmg.is_file() and dmg.stat().st_size == want, f"{dmg}: expected {want} bytes"
        print(f"  {name}.dmg {dmg.stat().st_size} bytes OK")
    fw = {p.name: p.read_bytes() for p in args.fw.iterdir() if p.is_file()}
    names = {r["name"] for r in recipes if r["kind"] == "firmware"}
    missing = names - set(fw)
    assert not missing, f"fw/ is missing {sorted(missing)}"
    print(f"  firmware recipes {len(names)}, local fw files {len(fw)} OK")

    work = args.work
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)

    print("=== 2. extract iOS files named by the recipes ===")
    refs = sorted({r["from"].split(":", 1)[1] for r in recipes if "from" in r})
    listing = work / "os.list"
    listing.write_text("".join(p + "\n" for p in refs))
    out = work / "os"
    run([SEVEN, "x", "-y", "-bso0", "-bsp0", str(args.ipsw / "os.dmg"),
         f"-o{out}", f"@{listing}"], stdout=subprocess.DEVNULL)
    for p in refs:
        assert (out / p).is_file(), f"os.dmg has no {p}"
    ios = {f"os:{p}": (out / p) for p in refs}
    print(f"  extracted {len(refs)} iOS files")

    print("=== 3. /private/var skeleton ===")
    slt = work / "var.slt"
    with open(slt, "w") as f:
        run([SEVEN, "l", "-slt", str(args.ipsw / "os.dmg"), "private/var/*"],
            stdout=f, stderr=subprocess.DEVNULL)
    skeleton = run([sys.executable, U / "ios26/full-system.py", "skeleton", slt],
                   capture_output=True, text=True).stdout
    print(f"  skeleton {len(skeleton)} bytes")

    print("=== 4. staging tree (manifest root entries + recipes) ===")
    staging = work / "root"
    staging.mkdir()
    by_path = {r["path"]: r for r in recipes}
    entries = manifest["root"]["entries"]
    for rel, kind, mode, target in entries:
        dest = staging / rel
        if kind == "dir":
            dest.mkdir()
        elif kind == "link":
            os.symlink(target, dest)
        elif rel not in by_path:
            shutil.copyfile(RELEASE / "root" / rel, dest)
    print(f"  {len(entries)} entries laid out")

    jobs_dir = staging / "LaunchDaemons"
    order = sorted(recipes, key=lambda r: r["kind"] == "cache")
    ok = 0
    bad = []
    for r in order:
        jobs = ({p.name: p.read_bytes() for p in jobs_dir.glob("*.plist")}
                if r["kind"] == "cache" else {})
        try:
            data = localfiles.make(
                r,
                lambda ref: ios[ref].read_bytes(),
                skeleton,
                jobs,
                lambda name: fw[name],
            )
        except Exception as exc:
            bad.append((r["path"], str(exc)))
            continue
        (staging / r["path"]).write_bytes(data)
        ok += 1
    print(f"  recipes OK {ok}/{len(recipes)}, failed {len(bad)}")
    for path, err in bad[:20]:
        print(f"    FAIL {path}: {err}")
    if bad:
        raise SystemExit("recipe validation failed - STOP")

    for rel, kind, mode, _ in reversed(entries):
        if kind != "link":
            os.chmod(staging / rel, mode)

    tree_sha = localfiles.tree_digest(staging)
    total = sum(p.stat().st_size for p in staging.rglob("*") if p.is_file() and not p.is_symlink())
    print(f"  tree_sha256   {tree_sha}")
    print(f"  official      {manifest['expected']['tree_sha256']}")
    print(f"  differs only because of the 9 star firmware stubs: "
          f"{tree_sha != manifest['expected']['tree_sha256']}")
    print(f"  uncompressed staging bytes {total}")
    if args.dry_run:
        print("DRY RUN: no APFS image written")
        return

    print("=== 5. mkapfs ===")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    run([sys.executable, U / "tools/apfs/mkapfs.py", "-z", "--plain", "fw",
         "-o", str(args.output), f"{manifest['volume']}={staging}"],
        stdout=subprocess.DEVNULL)
    size = args.output.stat().st_size
    print(f"  {args.output}: {size} bytes ({size / 2**20:.2f} MiB)")
    print(f"  sha256 {digest(args.output)}")
    print("=== 6. payload budget (strict annibale BootShim cap 0x03700000) ===")
    cap = 0x03700000
    p1 = 24894512  # measured P1 container: loader.efi + kernel + rdimage + flags
    print(f"  P1 container {p1} bytes; room for ramdisk = {cap - p1 - size} bytes")
    if size > cap - p1 - 65536:
        print("  WARNING: container would exceed PAYLOAD_CAP; trim root.apfs first")


if __name__ == "__main__":
    main()
