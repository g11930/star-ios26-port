#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage15-seq-gate.py

Turn every star_trace()/star_trace_s() call into an automatically numbered
checkpoint gate.

Why: a checkpoint stops the kernel dead, so one boot yields exactly one bit.
Fixed numbers (16/17/18/19) would need one compile per round and still only
answer "did we get past here".  Instead the gate keeps a running counter and
compares --checkpoint against 200 + seq, so a single boot with
loader_checkpoint = 200 + K stops at the K-th trace point of the whole boot
and writes out the entire log ring up to that point.  Bisect on K.

Existing literal checkpoints 1..15 in bsd_init.c / arm_vm_init etc. are below
200 and keep working unchanged.
"""
import os
import sys

ROOT = "/root/star26/star-native"
RET = os.path.join(ROOT, "osfmk/arm64/loader_return.c")
EXEC = os.path.join(ROOT, "bsd/kern/kern_exec.c")

GATE_IMPL = '''
/*
 * Bring-up aid: a running checkpoint number for the exec trace.
 *
 * loader_checkpoint() stops on an exact match, so a fixed number answers one
 * question per boot and needs a recompile to ask the next one.  Numbering the
 * trace points as they are reached lets a single build be bisected: with
 * loader_checkpoint = 200 + K the kernel stops at the K-th trace point and
 * hands the log ring -- everything written up to there -- to the loader.
 */
static uint64_t star_gate_seq;

void
star_gate(void)
{
	loader_checkpoint(200 + ++star_gate_seq);
}
'''

def patch_ret():
    src = open(RET, encoding="utf-8", errors="surrogateescape").read()
    if "star_gate(void)" in src:
        print("  loader_return.c: star_gate already present")
        return
    anchor = """void
loader_checkpoint(uint64_t n)
{
	if (loader_stub_slot[2] == n) {
		loader_jump(2, n);
	}
}
"""
    if anchor not in src:
        print("  !! loader_return.c: loader_checkpoint anchor not found")
        sys.exit(1)
    src = src.replace(anchor, anchor + GATE_IMPL, 1)
    open(RET, "w", encoding="utf-8", errors="surrogateescape").write(src)
    print("  loader_return.c: star_gate() added")


def patch_exec():
    src = open(EXEC, encoding="utf-8", errors="surrogateescape").read()
    if "star_gate" in src:
        print("  kern_exec.c: gate calls already present")
        return
    src = src.replace(
        "extern void loader_log_line(const char *line);",
        "extern void loader_log_line(const char *line);\nextern void star_gate(void);", 1)

    old_a = """	snprintf(line, sizeof(line), "\\nSTARX %s a=%lld b=%lld\\n", tag, a, b);
	loader_log_line(line);
}"""
    new_a = """	snprintf(line, sizeof(line), "\\nSTARX %s a=%lld b=%lld\\n", tag, a, b);
	loader_log_line(line);
	star_gate();
}"""
    old_b = """	snprintf(line, sizeof(line), "\\nSTARX %s %s a=%lld\\n", tag, s ? s : "(null)", a);
	loader_log_line(line);
}"""
    new_b = """	snprintf(line, sizeof(line), "\\nSTARX %s %s a=%lld\\n", tag, s ? s : "(null)", a);
	loader_log_line(line);
	star_gate();
}"""
    ok = 0
    if old_a in src:
        src = src.replace(old_a, new_a, 1); ok += 1
    if old_b in src:
        src = src.replace(old_b, new_b, 1); ok += 1
    if ok != 2:
        print("  !! kern_exec.c: helper bodies not matched (%d/2)" % ok)
        sys.exit(1)
    open(EXEC, "w", encoding="utf-8", errors="surrogateescape").write(src)
    print("  kern_exec.c: gate wired into both trace helpers")


print("stage15: sequence-numbered checkpoint gates")
patch_ret()
patch_exec()

# report
import subprocess
n = subprocess.run(["grep", "-c", "star_trace(", EXEC], capture_output=True, text=True).stdout.strip()
print("  trace call sites in kern_exec.c:", n)
print("done")
