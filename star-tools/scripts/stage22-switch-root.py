#!/usr/bin/env python3
"""stage22-switch-root.py [--check]

Install bsd/dev/star/star_switch_root.c (kern.annibale_switch_root) into the
star-native tree and register it in bsd/conf/files.  Idempotent: --check only
reports the current state.
"""
import os
import shutil
import sys

TREE = "/root/star26/star-native"
SRC = "/mnt/d/桌面/star26-deps/scripts/star_switch_root.c"
DST = os.path.join(TREE, "bsd/dev/star/star_switch_root.c")
FILES = os.path.join(TREE, "bsd/conf/files")
LINE = "bsd/dev/star/star_switch_root.c\tstandard\n"
ANCHOR = "bsd/dev/star/star_display_handoff.c\tstandard\n"

CHECK = "--check" in sys.argv


def read(p):
    with open(p, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def main():
    conf = read(FILES)
    registered = "bsd/dev/star/star_switch_root.c" in conf
    present = os.path.exists(DST)
    same = present and read(DST) == read(SRC)
    print("conf/files registered: %s" % registered)
    print("source present: %s  identical: %s" % (present, same))
    if CHECK:
        ok = registered and same
        print("STAGE22 %s" % ("PASS" if ok else "MISMATCH"))
        return 0 if ok else 1
    if not same:
        shutil.copyfile(SRC, DST)
        print("copied %s -> %s" % (SRC, DST))
    if not registered:
        if ANCHOR not in conf:
            raise SystemExit("anchor line missing from conf/files: %r" % ANCHOR)
        conf = conf.replace(ANCHOR, ANCHOR + LINE, 1)
        with open(FILES, "w", encoding="utf-8") as fh:
            fh.write(conf)
        print("registered in conf/files")
    print("STAGE22 DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
