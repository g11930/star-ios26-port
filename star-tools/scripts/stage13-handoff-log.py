#!/usr/bin/env python3
"""stage 13: give star_display_handoff.c a log channel that actually works.

Measured facts (s7b vs s16 logdump, same address f78f2450):
    s7b (panic return)  kernel returned: log at f78f2450, 536 bytes
    s16 (checkpoint 14) kernel returned: log at f78f2450,   0 bytes
536 bytes proves the loader ring (loader_log_line) works.  s16 writing nothing
means nothing on that path called it.

Why IOLog cannot work here:
  * star_display_handoff.o imports _IOLog, but NO object in the whole
    RELEASE_ARM64_BCM2837 build defines it (iokit/RELEASE only has
    IOStringFuncs.o -- IOLib.cpp is not compiled).  The symbol therefore lands
    undefined-weak and every call is a no-op.
  * Its real implementation (iokit/Kernel/IOLib.cpp:1518) would go through
    console_printbuf_putc -> console_write, not the loader ring, and it carries
    assertf(ml_get_interrupts_enabled() || ...), which panics if called with
    interrupts off.
  * CONFIG_NO_PRINTF_STRINGS makes the printf family no-ops that also discard
    the format strings at preprocessing time.

So route every line through loader_log_line(): same BSS, same loader_log_len
the loader polls live for its KERNEL BOOT CONSOLE card, and the same bytes that
land in the logdump partition.  Milestones become visible on the phone AND in
the dump, with no USB race.
"""
import io
import sys

P = "/root/star26/star-native/bsd/dev/star/star_display_handoff.c"

OLD_DECL = "extern void IOLog(const char *format, ...);\n"

NEW_DECL = """#include <stdarg.h>

extern void loader_log_line(const char *line);

/*
 * The loader's log ring is the only channel in this boot that produces text:
 * IOLog is undefined-weak in this build (see the file comment), and
 * CONFIG_NO_PRINTF_STRINGS discards printf's format strings outright.
 * loader_log_line() is lock-protected, masks interrupts itself, and appends
 * one complete line, which is exactly what the loader's live console card
 * parses and what the logdump partition keeps.
 */
static void
star_log(const char *format, ...)
{
\tchar line[256];
\tva_list ap;

\tva_start(ap, format);
\tvsnprintf(line, sizeof(line), format, ap);
\tva_end(ap);
\tloader_log_line(line);
}
"""


def main():
    s = io.open(P, encoding="utf-8").read()
    if "star_log(" in s:
        print("already patched")
        return 0
    if s.count(OLD_DECL) != 1:
        print("FAILED: IOLog declaration not found exactly once")
        return 1
    s = s.replace(OLD_DECL, NEW_DECL, 1)

    n = s.count("IOLog(")
    s = s.replace("IOLog(", "star_log(")
    print("  rewrote %d IOLog call(s)" % n)

    io.open(P, "w", encoding="utf-8").write(s)
    out = io.open(P, encoding="utf-8").read()
    print("  remaining IOLog:", out.count("IOLog("))
    print("  star_log calls:", out.count("star_log("))
    return 0


if __name__ == "__main__":
    sys.exit(main())
