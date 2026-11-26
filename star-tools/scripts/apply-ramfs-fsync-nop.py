#!/usr/bin/env python3
"""
s67: make ramfs_fsync() a no-op, matching dada (which uses nop_fsync).

Root cause chain (proven in s66):
  ramfs_fsync -> ramfs_disk_sync -> annibale_ufs_var_io returns EBUSY/ENXIO
  -> logd fsync assert -> __builtin_trap (SIGTRAP) -> 16x respawn loop
  -> launchd busy respawning, backboardd SEND unanswered -> stuck at 98%.

We keep ramfs_sync_mapping() (in-memory mmap sync) and the seed marker; only
the UFS disk writeback and its error return are removed.  One line of behavior.

Idempotent, backed up, strict anchor.
Usage: python3 apply-ramfs-fsync-nop.py [--check]
"""
import os
import shutil
import sys

SRC = "/root/star26/star-native/bsd/miscfs/ramfs/ramfs_fsctl.inc"
CHECK = "--check" in sys.argv

ANCHOR = """	if (rm != NULL && node->rn_ino == RAMFS_ROOT_INO && !rm->rm_seed_done) {
		ramfs_disk_mark_seed_done(rm);
	}
	return ramfs_disk_sync(rm);
}
"""

REPL = """	if (rm != NULL && node->rn_ino == RAMFS_ROOT_INO && !rm->rm_seed_done) {
		ramfs_disk_mark_seed_done(rm);
	}
	/* s67: dada's ramfs uses nop_fsync -- never write back to UFS here.
	 * ramfs_disk_sync() -> annibale_ufs_var_io() fails (EBUSY/ENXIO) in this
	 * environment; the error trips logd's fsync assert into SIGTRAP, causing
	 * a 16x spawn/crash loop that starves launchd and stalls backboardd.
	 * The ramfs is volatile anyway (contents die at reset), so a no-op fsync
	 * loses nothing.  Keep ramfs_sync_mapping() above for mmap coherence. */
	return 0;
}
"""


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(SRC, "r", encoding="utf-8") as f:
        data = f.read()

    if "s67: dada's ramfs uses nop_fsync" in data:
        print("[skip] already applied")
        return

    cnt = data.count(ANCHOR)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need exactly 1)")
        sys.exit(2)
    print("[check OK] anchor found once")

    if CHECK:
        return

    bak = SRC + ".s67.bak"
    if not os.path.exists(bak):
        shutil.copy2(SRC, bak)
        print(f"[backup] {bak}")

    data = data.replace(ANCHOR, REPL, 1)
    with open(SRC, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] ramfs_fsync -> return 0")


if __name__ == "__main__":
    main()
