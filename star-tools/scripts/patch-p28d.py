#!/usr/bin/env python3
"""P28 fix: the probes must call printf, not kprintf.

This build has CONFIG_NO_KPRINTF_STRINGS, so pexpert.h turns kprintf into
    #define kprintf(x, ...) _consume_kprintf_args(0, ## __VA_ARGS__)
which throws the format string away at preprocessing time.  That is why the first two
objects were byte-identical to the unpatched ones.  printf() is a real function
(pexpert/pexpert/protos.h) and its literals do land in the kernel, which is how the
existing drivers get their lines into the log.
"""
import sys

SLEH = "/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c"
EXIT = "/root/star26/kbuild/xnu-12377.121.6/bsd/kern/kern_exit.c"

for path in (SLEH, EXIT):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    n = text.count("kprintf(\"P28")
    if n == 0:
        print("%s: nothing to change" % path)
        continue
    text = text.replace("kprintf(\"P28", "printf(\"P28")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("%s: %d probe(s) switched to printf" % (path, n))
