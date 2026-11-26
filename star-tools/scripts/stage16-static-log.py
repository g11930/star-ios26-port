#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage16 -- P0: make the kernel log channel observable without any printf family.

Facts established before this patch (read-only, in this session):
  * strings(kernel) contains "star: milestone %s", "STARX %s a=%lld b=%lld".
  * _star_log / _star_trace / _vsnprintf / _snprintf / _loader_log_line are all
    present in the unstripped kernel; the bsd objects really import
    U _loader_log_line / U _vsnprintf and loader_return.o exports T _loader_log_line.
  * __doprnt() in osfmk/kern/printf.c is a full implementation, not a stub.
  * Yet s20 at checkpoint 14 reported "kernel returned: log at f78ee450, 0 bytes".
    loader_jump() passes x3 = loader_log_len, so the ring really was empty.

So "printf was stripped" does not explain it.  This patch removes the last
uncertainty by making every diagnostic line consist of static literals and
hand-written hex only, and by adding a preflight at cp14 that:
  - writes through loader_log_line()          (channel A)
  - writes through loader_log_putc()          (channel B, different wrapper)
  - reports loader_log_len before and after   (channel C, the very counter the
    loader stub hands back as x3)

If the staged log now has STAR0/STARL text, the ring works and the old
formatted lines were the problem.  If it is still 0 bytes, the problem is in
the ring/counter itself (mapping, BSS copy, or the loader's view), which the
before/after numbers will pin down.

No architecture, boot chain, driver or control-flow change.  checkpoints 1..15
and the star_gate() sequence gates are untouched.
"""
import io
import os
import sys

ROOT = "/root/star26/star-native"
EXEC = os.path.join(ROOT, "bsd/kern/kern_exec.c")
HAND = os.path.join(ROOT, "bsd/dev/star/star_display_handoff.c")
INIT = os.path.join(ROOT, "bsd/kern/bsd_init.c")

# ---------------------------------------------------------------- kern_exec.c
OLD_EXEC = '''extern void loader_log_line(const char *line);
extern void star_gate(void);

void
star_trace(const char *tag, long long a, long long b)
{
\tchar line[128];

\tsnprintf(line, sizeof(line), "\\nSTARX %s a=%lld b=%lld\\n", tag, a, b);
\tloader_log_line(line);
\tstar_gate();
}

void
star_trace_s(const char *tag, const char *s, long long a)
{
\tchar line[192];

\tsnprintf(line, sizeof(line), "\\nSTARX %s %s a=%lld\\n", tag, s ? s : "(null)", a);
\tloader_log_line(line);
\tstar_gate();
}
'''

NEW_EXEC = '''extern void loader_log_line(const char *line);
extern void star_gate(void);

/*
 * P0: build the line from static literals and hand-written hex.  No snprintf /
 * vsnprintf / __doprnt anywhere on this path: if the printf family produces an
 * empty string, loader_log_line("") writes zero bytes and the whole boot looks
 * silent.  Everything below is plain byte copies.
 */
static char *
star_copy(char *p, const char *s)
{
\twhile (*s != 0) {
\t\t*p++ = *s++;
\t}
\treturn p;
}

static char *
star_hex(char *p, unsigned long long v)
{
\tstatic const char digits[] = "0123456789abcdef";
\tchar tmp[16];
\tint n = 0;

\tdo {
\t\ttmp[n++] = digits[v & 0xf];
\t\tv >>= 4;
\t} while (v != 0);
\t*p++ = '0';
\t*p++ = 'x';
\twhile (n > 0) {
\t\tp++[0] = tmp[--n];
\t}
\treturn p;
}

void
star_trace(const char *tag, long long a, long long b)
{
\tchar line[160];
\tchar *p = line;

\tp = star_copy(p, "\\nSTARX ");
\tp = star_copy(p, tag);
\tp = star_copy(p, " a=");
\tp = star_hex(p, (unsigned long long)a);
\tp = star_copy(p, " b=");
\tp = star_hex(p, (unsigned long long)b);
\tp = star_copy(p, "\\n");
\t*p = 0;
\tloader_log_line(line);
\tstar_gate();
}

void
star_trace_s(const char *tag, const char *s, long long a)
{
\tchar line[256];
\tchar *p = line;

\tp = star_copy(p, "\\nSTARX ");
\tp = star_copy(p, tag);
\tp = star_copy(p, " ");
\tp = star_copy(p, s ? s : "(null)");
\tp = star_copy(p, " a=");
\tp = star_hex(p, (unsigned long long)a);
\tp = star_copy(p, "\\n");
\t*p = 0;
\tloader_log_line(line);
\tstar_gate();
}
'''

# ------------------------------------------------------- star_display_handoff.c
OLD_HAND_LOG = '''static void
star_log(const char *format, ...)
{
\tchar line[256];
\tva_list ap;

\tva_start(ap, format);
\tvsnprintf(line, sizeof(line), format, ap);
\tva_end(ap);
\tloader_log_line(line);
}
'''

NEW_HAND_LOG = '''/*
 * P0: emit the format string itself as a static literal.  No vsnprintf: an
 * empty formatted line makes loader_log_line() append nothing at all, which is
 * exactly what checkpoint 14 reported ("0 bytes").  Every call site keeps its
 * own distinctive text, so the milestones remain identifiable.
 */
static void
star_log(const char *format, ...)
{
\tloader_log_line("\\nSTARL ");
\tloader_log_line(format);
\tloader_log_line("\\n");
}
'''

OLD_MILESTONE = '''void
star_display_milestone(const char *tag)
{
\tstar_log("star: milestone %s\\n", tag);
}
'''

NEW_MILESTONE = '''void
star_display_milestone(const char *tag)
{
\tloader_log_line("\\nstar: milestone ");
\tloader_log_line(tag);
\tloader_log_line("\\n");
}
'''

# ----------------------------------------------------------------- bsd_init.c
OLD_INIT_DECL = '''/* star stage 10: the loader's bring-up checkpoint */
extern void loader_checkpoint(uint64_t);
'''

NEW_INIT_DECL = '''/* star stage 10: the loader's bring-up checkpoint */
extern void loader_checkpoint(uint64_t);

/* star P0: three independent probes of the loader log ring, printf-free. */
extern void loader_log_line(const char *line);
extern void loader_log_putc(char c);
extern uint32_t loader_log_len;

static void
star_puthex32(uint32_t v)
{
\tstatic const char hex[] = "0123456789abcdef";
\tchar buf[10];
\tint i;

\tfor (i = 7; i >= 0; i--) {
\t\tbuf[i] = hex[v & 0xf];
\t\tv >>= 4;
\t}
\tbuf[8] = '\\n';
\tbuf[9] = 0;
\tloader_log_line(buf);
}

static void
star_log_preflight(void)
{
\tuint32_t before = loader_log_len;

\t/* channel A: the same wrapper the formatted lines used */
\tloader_log_line("\\nSTAR0: bsdinit_task alive, cp14 preflight (channel A)\\n");
\t/* channel B: bypass loader_log_line, go straight to the putc wrapper */
\tloader_log_putc('S');
\tloader_log_putc('T');
\tloader_log_putc('A');
\tloader_log_putc('R');
\tloader_log_putc('0');
\tloader_log_putc('B');
\tloader_log_putc('\\n');
\t/* channel C: the counter loader_jump() hands back in x3 */
\tloader_log_line("STAR0: log_len before=0x");
\tstar_puthex32(before);
\tloader_log_line("STAR0: log_len after=0x");
\tstar_puthex32(loader_log_len);
}
'''

OLD_INIT_CALL = '''\tstar_display_milestone("launchd");
\tloader_checkpoint(14);
'''

NEW_INIT_CALL = '''\tstar_display_milestone("launchd");
\tstar_log_preflight();
\tloader_checkpoint(14);
'''


def read(path):
    return io.open(path, encoding="utf-8", errors="surrogateescape").read()


def write(path, s):
    io.open(path, "w", encoding="utf-8", errors="surrogateescape").write(s)


def replace_one(s, name, old, new, path):
    n = s.count(old)
    if n != 1:
        print("FAIL %s: %d matches for the anchor in %s" % (name, n, path))
        return None
    return s.replace(old, new, 1)


def main():
    check = "--check" in sys.argv
    edits = [
        (EXEC, "kern_exec helper", OLD_EXEC, NEW_EXEC, "star_copy("),
        (HAND, "star_log", OLD_HAND_LOG, NEW_HAND_LOG, "STARL "),
        (HAND, "milestone", OLD_MILESTONE, NEW_MILESTONE, "star: milestone "),
        (INIT, "preflight decl", OLD_INIT_DECL, NEW_INIT_DECL, "star_log_preflight(void)"),
        (INIT, "preflight call", OLD_INIT_CALL, NEW_INIT_CALL, "star_log_preflight();"),
    ]
    cache = {}
    for path, _, _, _, _ in edits:
        cache[path] = read(path)

    if check:
        ok = True
        for path, name, _, _, marker in edits:
            present = marker in cache[path]
            print("  %-18s %s" % (name, "PRESENT" if present else "MISSING"))
            ok = ok and present
        print("CHECK", "PASS" if ok else "FAIL")
        return 0 if ok else 1

    for path, name, old, new, _ in edits:
        s = cache[path]
        if new.strip() in s:
            print("  %-18s already applied" % name)
            continue
        out = replace_one(s, name, old, new, path)
        if out is None:
            return 1
        cache[path] = out
        print("  %-18s patched" % name)

    for path, s in cache.items():
        write(path, s)

    # verify
    for path, name, _, _, marker in edits:
        assert marker in read(path), "%s: marker %r missing after write" % (name, marker)
    e = read(EXEC)
    assert OLD_EXEC not in e, "kern_exec.c still has the snprintf helper"
    assert "snprintf(line, sizeof(line)" not in e, "kern_exec.c still formats a trace line"
    h = read(HAND)
    assert "vsnprintf(" not in h, "star_display_handoff.c still formats lines"
    print("stage16 DONE: no printf family in the diagnostic path")
    return 0


if __name__ == "__main__":
    sys.exit(main())
