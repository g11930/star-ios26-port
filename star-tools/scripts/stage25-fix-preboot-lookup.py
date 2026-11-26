#!/usr/bin/env python3
"""stage25: the preboot uuid lookup in apfs_mount_common used an empty list.

stage24 asked apfs_preboot_uuid_scan() for the preboot volume, but that walks
apfs_mounts, and the mount being set up has not been linked into it yet at that
point -- so the very first mount (the one that matters) sees an empty list and
gets ENOENT, and STARPB never appears.

The container is already open here, so ask it directly.
"""
import io
import os
import sys

VFS = "/root/star26/star-native/bsd/miscfs/apfs/apfs_vfsops.c"

OLD = "\t\tif (!published && apfs_preboot_uuid_scan(pb, sizeof(pb)) == 0) {"
NEW = "\t\tif (!published && apfs_vol_preboot_uuid(&am->am_nx, pb, sizeof(pb)) == 0) {"


def read(p):
    with io.open(p, "r", encoding="utf-8", errors="surrogateescape") as f:
        return f.read()


def write(p, s):
    with io.open(p, "w", encoding="utf-8", errors="surrogateescape", newline="") as f:
        f.write(s)


def main(apply):
    v = read(VFS)
    if NEW in v:
        print("stage25: already applied")
        return
    if OLD not in v:
        sys.exit("stage25: stage24 block not found (was it applied?)")
    v = v.replace(OLD, NEW, 1)
    print("stage25: apfs_mount_common asks its own container for the preboot volume")
    if apply:
        write(VFS, v)
        print("stage25: WRITTEN")
    else:
        print("stage25: dry run")


if __name__ == "__main__":
    main("--check" not in sys.argv)
