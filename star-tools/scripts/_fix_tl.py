#!/usr/bin/env python3
"""
Fix annibale_tl() in bsd/dev/star/annibale_input.c:

    printf("%s", line);   ->  loader_log_putc(line[i]) per character

Why: this tree sets CONFIG_NO_PRINTF_STRINGS (config/MASTER:309), so libkern.h:191
turns printf() into `do {} while (0)`.  Every "tl:" latency line -- tl: s (swap
handed over), tl: v (frame drawn into panel), tl: l (panel latch), and
"milestone: first_frame" -- was being silently dropped.

annibale_goodix.c's goodix_trace() in the same directory already does it right
with loader_log_putc, and says so in a comment: printf's output "never reaches
the log" at that point, while loader_log_putc -- "the same path the latency
lines take" -- does.  annibale_tl() is exactly that path, so it uses it too.

Idempotent: re-running changes nothing once applied.
"""
import hashlib
import os
import shutil
import sys

PATH = "/root/star26/star-native/bsd/dev/star/annibale_input.c"

OLD = '''/* The touch driver's timing lines ("tl: ..."), on the kernel log. */
void annibale_tl(const char *format, ...) __printflike(1, 2);

void
annibale_tl(const char *format, ...)
{
\tchar line[192];
\tva_list list;

\tva_start(list, format);
\tvsnprintf(line, sizeof(line), format, list);
\tva_end(list);
\tprintf("%s", line);
}
'''

NEW = '''/*
 * The touch driver's timing lines ("tl: ..."): tl: s (a swap handed over),
 * tl: v (a frame drawn into the panel), tl: l (the panel latched a frame) and
 * "milestone: first_frame".
 *
 * Through loader_log_putc, not printf: this build has CONFIG_NO_PRINTF_STRINGS,
 * so libkern.h makes printf() a `do {} while (0)` and every one of these lines
 * was dropped before it reached the log.  loader_log_putc is the same path the
 * goodix driver's lines take (bsd/dev/star/annibale_goodix.c, goodix_trace),
 * and it works both inside the BSD init and long after, when userland runs.
 * The callers all end their format with "\\n"; this adds nothing of its own.
 */
extern void loader_log_putc(char c);

void annibale_tl(const char *format, ...) __printflike(1, 2);

void
annibale_tl(const char *format, ...)
{
\tchar line[192];
\tva_list list;
\tint n;

\tva_start(list, format);
\tn = vsnprintf(line, sizeof(line), format, list);
\tva_end(list);
\tif (n < 0) {
\t\treturn;
\t}
\tif (n > (int) sizeof(line) - 1) {
\t\tn = (int) sizeof(line) - 1;
\t}
\tfor (int i = 0; i < n; i++) {
\t\tloader_log_putc(line[i]);
\t}
}
'''


def main():
    if not os.path.exists(PATH):
        print("MISSING: %s" % PATH)
        return 1

    src = open(PATH, "r", encoding="utf-8").read()

    if "loader_log_putc(line[i])" in src:
        print("ALREADY PATCHED (loader_log_putc present) -- nothing to do")
        return 0

    if OLD not in src:
        print("PATTERN NOT FOUND -- abort, inspect by hand")
        idx = src.find("annibale_tl(const char *format, ...)")
        if idx >= 0:
            print("--- context around annibale_tl ---")
            print(src[max(0, idx - 300):idx + 400])
        return 2

    if src.count("printf(\"%s\", line);") != 1:
        print("UNEXPECTED: printf(\"%s\", line); appears %d times"
              % src.count('printf("%s", line);'))
        return 3

    bak = PATH + ".s198-pre-tlfix.bak"
    if not os.path.exists(bak):
        shutil.copy2(PATH, bak)
        print("backup -> %s" % bak)

    out = src.replace(OLD, NEW, 1)
    open(PATH, "w", encoding="utf-8").write(out)

    print("patched %s" % PATH)
    print("  md5 before: %s" % hashlib.md5(src.encode()).hexdigest())
    print("  md5 after : %s" % hashlib.md5(out.encode()).hexdigest())

    # sanity: the file must still have exactly one annibale_tl definition body
    print("  annibale_tl occurrences: %d (expect 3: extern at top, decl, body)"
          % out.count("annibale_tl"))
    print("  printf( occurrences left in file: %d" % out.count("printf("))
    return 0


if __name__ == "__main__":
    sys.exit(main())
