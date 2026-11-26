#!/usr/bin/env python3
"""
s79: log user-space BRK and undefined-instruction exceptions (tid/pc/
label-instr) so logd's repeated SIGTRAP death site can be pinned.

Background: logd dies 16x per boot with SIGTRAP ~0.1-1.2s into each life
(xstat 5); the logdtrace sampler only catches it ALIVE, grinding in
dyld4::Loader::runInitializersBottomUp's PAC-auth loop (autdb/xpacd/cmp,
one kernel trap per instruction under pac_emu).  The actual death site is
unknown.  handle_user_breakpoint + handle_uncategorized are the two kernel
entry points that see the faulting pc before the signal is delivered.

Boot-arg star_traplog=1 (default off), first 200 events per boot.
Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-traplog.py [--check]
"""
import os
import shutil
import sys

S = "/root/star26/star-native/osfmk/arm64/sleh.c"
CHECK = "--check" in sys.argv

OLD_VAR = "static int      pac_emu_enabled = -1;"
NEW_VAR = OLD_VAR + '''
static int      star_traplog_enabled = -1;
static uint32_t star_traplog_count;'''

OLD_BRK = '''handle_user_breakpoint(arm_saved_state_t *state, uint64_t esr __unused)
{
	exception_type_t           exception = EXC_BREAKPOINT;
	mach_exception_data_type_t codes[2]  = {EXC_ARM_BREAKPOINT};
	mach_msg_type_number_t     numcodes  = 2;'''
NEW_BRK = OLD_BRK + '''

	if (__improbable(star_traplog_enabled < 0)) {
		uint32_t v = 1;
		(void) PE_parse_boot_argn("star_traplog", &v, sizeof(v));
		star_traplog_enabled = v ? 1 : 0;
	}
	if (star_traplog_enabled && star_traplog_count < 200) {
		star_traplog_count++;
		char note[160];
		snprintf(note, sizeof(note),
		    "\\nStarTrapLog: brk tid %llu pc 0x%llx label 0x%x\\n",
		    (unsigned long long)thread_tid(current_thread()),
		    (unsigned long long)get_saved_state_pc(state),
		    (uint32_t)ISS_BRK_COMMENT(esr));
		loader_log_line(note);
	}'''

OLD_UNC = '''	mach_exception_data_type_t codes[2]  = {EXC_ARM_UNDEFINED};
	mach_msg_type_number_t     numcodes  = 2;
	uint32_t                   instr     = 0;

	COPYIN(get_saved_state_pc(state), (char *)&instr, sizeof(instr));'''
NEW_UNC = OLD_UNC + '''

	if (__improbable(star_traplog_enabled < 0)) {
		uint32_t v = 1;
		(void) PE_parse_boot_argn("star_traplog", &v, sizeof(v));
		star_traplog_enabled = v ? 1 : 0;
	}
	if (star_traplog_enabled && star_traplog_count < 200) {
		star_traplog_count++;
		char note[160];
		snprintf(note, sizeof(note),
		    "\\nStarTrapLog: undef tid %llu pc 0x%llx instr 0x%08x\\n",
		    (unsigned long long)thread_tid(current_thread()),
		    (unsigned long long)get_saved_state_pc(state), instr);
		loader_log_line(note);
	}'''

PATCHES = [
    ("var",  OLD_VAR, NEW_VAR, "star_traplog_enabled"),
    ("brk",  OLD_BRK, NEW_BRK, "StarTrapLog: brk"),
    ("unc",  OLD_UNC, NEW_UNC, "StarTrapLog: undef"),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(S, "r", encoding="utf-8") as f:
        data = f.read()
    changed = False
    for label, old, new, token in PATCHES:
        if token in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        data = data.replace(old, new, 1)
        changed = True
    if CHECK:
        print("done")
        return
    if changed:
        bak = S + ".s79.bak"
        if not os.path.exists(bak):
            shutil.copy2(S, bak)
            print(f"[backup] {bak}")
        with open(S, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] sleh.c")
    print("done")


if __name__ == "__main__":
    main()
