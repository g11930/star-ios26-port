#!/usr/bin/env python3
"""stage 4: fix the s1 early-boot panic (hardcoded kalloc section offsets).

s1 died at _kalloc_type_view_copy +0xd4 with ESR 0x9600004f
(EL1 data abort, write, permission fault L3) because the Linux/cctools
build fixup in osfmk/kern/kalloc.c hardcoded the __kalloc_type/__kalloc_var
section offsets measured on the K90 kernel.  star-native removed most
platform drivers, so those offsets now point into the read-only __TEXT
segment.  kt_start = &_mh_execute_header + 0x1d0a08 = 0xfffffff0071d4a08
was exactly x1/x21 in the panic dump; far = +0x28 is where
kalloc_type_view_copy() writes ktv->kt_flags.

Measured with parse-kalloc-sections.py against the star-native
mach.release.bcm2837.unstripped (11,545,504 B):
    __kalloc_type delta 0x1ab358 size 0x13680
    __kalloc_var  delta 0x1a3c48 size 0x7710
These are equal-length immediate replacements, so the section layout does
not change; the values stay valid for the rebuilt kernel.  Re-run
parse-kalloc-sections.py after ANY change that adds/removes a driver.

Idempotent; --check verifies without writing.
"""
import argparse
import os

DST = "/root/star26/star-native"
REL = "osfmk/kern/kalloc.c"

REPL = [
    ("0x1d0a08", "0x1ab358"),   # __kalloc_type delta (fixed)
    ("0x1c8c18", "0x1a3c48"),   # __kalloc_var  delta (var)
    ("0x13e80",  "0x13680"),    # __kalloc_type size
    ("0x7df0",   "0x7710"),     # __kalloc_var  size
]

OLD_COMMENT = (" * before __TEXT, so their offsets are stable across .text edits. */")
NEW_COMMENT = (" * before __TEXT.  These offsets are measured on the star-native kernel\n"
               "\t\t\t * by scripts/parse-kalloc-sections.py; recompute them after any change\n"
               "\t\t\t * that alters the section layout, or kalloc_type_view_copy() will write\n"
               "\t\t\t * into __TEXT and panic at boot (s1, 2026-11-15). */")


def path():
    return os.path.join(DST, REL)


def check():
    text = open(path(), errors="replace").read()
    print("=== stage 4 CHECK: %s ===" % REL)
    bad = 0
    for old, new in REPL:
        n_old, n_new = text.count(old), text.count(new)
        ok = n_old == 0 and n_new == 2
        bad += 0 if ok else 1
        print("  %-4s %-12s old=%d (want 0)  %-12s new=%d (want 2)" %
              ("OK" if ok else "FAIL", old, n_old, new, n_new))
    n = text.count(OLD_COMMENT)
    ok = n == 0
    bad += 0 if ok else 1
    print("  %-4s stale 'stable across .text edits' comment: %d (want 0)" %
          ("OK" if ok else "FAIL", n))
    n = text.count("parse-kalloc-sections.py")
    ok = n == 2
    bad += 0 if ok else 1
    print("  %-4s new measurement comments: %d (want 2)" % ("OK" if ok else "FAIL", n))
    if bad:
        raise SystemExit("stage 4 check failed: %d mismatch(es)" % bad)
    print("PASS")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    if args.check:
        check()
        return

    p = path()
    text = open(p, errors="replace").read()
    print("=== stage 4: star-native kalloc section offsets ===")
    for old, new in REPL:
        n = text.count(old)
        if n == 0:
            if text.count(new) == 2:
                print("  %-12s -> %-12s already applied" % (old, new))
                continue
            raise SystemExit("FAILED: %s occurs %d times" % (old, n))
        if n != 2:
            raise SystemExit("FAILED: expected 2 occurrences of %s, got %d" % (old, n))
        text = text.replace(old, new)
        print("  %-12s -> %-12s (%d)" % (old, new, n))
    n = text.count(OLD_COMMENT)
    if n:
        if n != 2:
            raise SystemExit("FAILED: comment occurs %d times" % n)
        text = text.replace(OLD_COMMENT, NEW_COMMENT)
        print("  rewrote %d stale comments" % n)
    with open(p, "w") as fh:
        fh.write(text)
    check()


if __name__ == "__main__":
    main()
