#!/usr/bin/env python3
"""
s72b: build fix for apply-threadstate-probe.py -- the bsd-side include of
<kern/thread.h> does not expose the osfmk TH_* bits in this tree (build
error: use of undeclared identifier 'TH_WAIT').  Restate the one bit we
need as STAR_TH_WAIT locally.  Idempotent, backed up, strict anchors.
Usage: python3 apply-threadstate-fix1.py [--check]
"""
import os
import shutil
import sys

B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

OLD_DEF = "extern int star_msgprobe_thread_diag(void *thread, uint64_t *out);"
NEW_DEF = OLD_DEF + '''

/* s72b: the bsd-side <kern/thread.h> does not expose the osfmk TH_* bits
 * in this tree (build error: use of undeclared identifier 'TH_WAIT'), so
 * restate the one bit we need.  Value from osfmk/kern/thread.h:523. */
#define STAR_TH_WAIT 0x01'''

OLD_USE = "if (!(dg[0] & TH_WAIT)) {"
NEW_USE = "if (!(dg[0] & STAR_TH_WAIT)) {"

PATCHES = [
    (B, "b-define", OLD_DEF, NEW_DEF),
    (B, "b-use", OLD_USE, NEW_USE),
]


SKIP_TOKEN = {
    "b-define": "#define STAR_TH_WAIT",
    "b-use":    "STAR_TH_WAIT))",
}


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if SKIP_TOKEN[label] in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s72.bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print(f"[backup] {bak}")
        data = data.replace(old, new, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"[patched] {label}")
    print("done")


if __name__ == "__main__":
    main()
