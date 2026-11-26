#!/usr/bin/env python3
"""P28: probes must go through IOLog.

kprintf and printf are both neutered here (CONFIG_NO_KPRINTF_STRINGS /
CONFIG_NO_PRINTF_STRINGS): the format string is macro-replaced by
_consume_kprintf_args(0, ...) / _consume_printf_args(0, ...), so the literal never reaches
the object.  Real driver lines in this log come from IOLog(), which is a function and ends
up in os_log_with_args().
"""
import sys

SLEH = "/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c"
EXIT = "/root/star26/kbuild/xnu-12377.121.6/bsd/kern/kern_exit.c"
INCLUDE = "#include <IOKit/IOLib.h>\n"

for path, tag in ((SLEH, "P28FAULT"), (EXIT, "P28EXIT")):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    n = 0
    for old in ('printf("%s' % tag, 'kprintf("%s' % tag):
        n += text.count(old)
        text = text.replace(old, 'IOLog("%s' % tag)
    print("%s: %d call(s) -> IOLog" % (path, n))

    if INCLUDE not in text:
        # put it right after the first include line so the rest of the block order stands
        i = text.index("\n#include ")
        text = text[:i + 1] + INCLUDE + text[i + 1:]
        print("%s: include added" % path)

    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
