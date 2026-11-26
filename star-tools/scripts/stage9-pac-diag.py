#!/usr/bin/env python3
"""stage 9: make the invalid-SP fault legible without kprintf.

Why this exists
---------------
The s7 staging log carries a complete kernel panic (see 2026-11-15.md), but it is
958 bytes long and the register table panic_plain prints is cut off at x24 -- so
the three registers that matter for "Invalid kernel stack pointer" (sp, fp, pc of
the faulting context) never made it out.

Two facts shape the fix:

  * pexpert/arm/pe_kprintf.c:69 hands kprintf's characters to loader_log_putc, so
    anything kprintf prints ends up in the loader's log ring -- but that ring held
    NOT ONE character before the fault, which means the fault happened before
    kprintf was usable at all.  A diagnostic that goes through printf() would be
    lost the same way.
  * osfmk/arm64/loader_return.c::loader_log_line() writes straight into the ring
    under its own lock, with no kprintf, no console and no formatting service
    involved.  That is the only channel proven to work at this point in the boot.

So: one compact STARSP line, through loader_log_line, before the table.  Plus the
pac_emu notes, which were printf() and therefore invisible.

Nothing here changes behaviour: no register, no control flow, no state.  Boot-arg
pac_emu=0 still disables the emulation exactly as before.
"""
import re
import sys

SLEH = "/root/star26/star-native/osfmk/arm64/sleh.c"

# ---------------------------------------------------------------- 1. prototypes
OLD_DECL = "extern void loader_fault_log(const char *, uint64_t, uint64_t, uint32_t, uint64_t);\n"
NEW_DECL = (OLD_DECL +
    "/* star stage 9: the ring writer and a formatter, both without kprintf (see loader_return.c) */\n"
    "extern void loader_log_line(const char *);\n"
    "extern int snprintf(char *, size_t, const char *, ...);\n"
    "static uint64_t star_fault_seq;\n")

# ------------------------------------------------- 2. the STARSP line at the top
OLD_PANIC = """	ss_valid = is_saved_state64(ss);
	arm_saved_state64_t *state = saved_state64(ss);
	loader_fault_log(msg, state->pc, state->lr, state->esr, state->far);
"""
NEW_PANIC = """	ss_valid = is_saved_state64(ss);
	arm_saved_state64_t *state = saved_state64(ss);
	/*
	 * star stage 9: the table panic_plain prints below is cut off by the log's budget
	 * (958 bytes on the last run, ending at x24), and sp -- the very register this
	 * handler is called about -- is in the part that is lost.  One compact line first,
	 * straight into the loader's ring, so the answer survives the truncation.
	 */
	{
		thread_t ft = current_thread();
		vm_offset_t ktop = (ft != NULL) ? (vm_offset_t)ft->machine.kstackptr : 0;
		char star_line[224];

		snprintf(star_line, sizeof(star_line),
		    "\\nSTARSP #%llu sp=0x%llx fp=0x%llx pc=0x%llx lr=0x%llx cpsr=0x%x"
		    " ktop=0x%llx thr=0x%llx tid=%d\\n",
		    (unsigned long long)++star_fault_seq,
		    (unsigned long long)state->sp, (unsigned long long)state->fp,
		    (unsigned long long)state->pc, (unsigned long long)state->lr,
		    (unsigned)state->cpsr, (unsigned long long)ktop,
		    (unsigned long long)(uintptr_t)ft,
		    (ft != NULL) ? ft->thread_id : -1);
		loader_log_line(star_line);
	}
	loader_fault_log(msg, state->pc, state->lr, state->esr, state->far);
"""

# ------------------------------------------- 3. pac_emu notes: printf -> the ring
OLD_UNHANDLED = """		pac_emu_unhandled_logged++;
		printf("pac_emu: unhandled 0x%08x at pc 0x%llx\\n",
		    instr, (unsigned long long)pc);
"""
NEW_UNHANDLED = """		char note[128];
		pac_emu_unhandled_logged++;
		snprintf(note, sizeof(note), "\\npac_emu: unhandled 0x%08x at pc 0x%llx\\n",
		    instr, (unsigned long long)pc);
		loader_log_line(note);
"""

OLD_FIRST = """	if (__improbable(pac_emu_hits == 1)) {
		printf("pac_emu: software PAuth active, first 0x%08x at pc 0x%llx\\n",
		    instr, (unsigned long long)pc);
	}
"""
NEW_FIRST = """	if (__improbable(pac_emu_hits == 1)) {
		char note[144];
		snprintf(note, sizeof(note),
		    "\\npac_emu: software PAuth active, first 0x%08x at pc 0x%llx\\n",
		    instr, (unsigned long long)pc);
		loader_log_line(note);
	}
"""

EDITS = [
    ("prototypes", OLD_DECL, NEW_DECL),
    ("STARSP line", OLD_PANIC, NEW_PANIC),
    ("pac_emu unhandled note", OLD_UNHANDLED, NEW_UNHANDLED),
    ("pac_emu first-hit note", OLD_FIRST, NEW_FIRST),
]


def main():
    src = open(SLEH).read()
    if "STARSP" in src:
        print("already patched (STARSP present) -- nothing to do")
        return 0
    for name, old, new in EDITS:
        n = src.count(old)
        if n != 1:
            print("FAILED %s: expected 1 match, found %d" % (name, n))
            return 1
        src = src.replace(old, new, 1)
        print("  applied: %s" % name)
    assert "STARSP #%llu" in src
    open(SLEH, "w").write(src)
    print("patched %s" % SLEH)
    print("  STARSP  : %d" % src.count("STARSP"))
    print("  log_line: %d" % src.count("loader_log_line("))
    return 0


if __name__ == "__main__":
    sys.exit(main())
