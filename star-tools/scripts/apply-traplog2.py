#!/usr/bin/env python3
"""
s80: fix the s79 traplog -- the undef (uncategorized) hook logged every
routine PAC-emulation trap (each PAC instr raises one) and consumed the
shared 200-event cap before logd's fatal BRK ever reached the log.

Changes:
 - remove the undef log block from handle_uncategorized entirely;
 - brk hook: own counter, cap raised to 500.
Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-traplog2.py [--check]
"""
import os
import shutil
import sys

S = "/root/star26/star-native/osfmk/arm64/sleh.c"
CHECK = "--check" in sys.argv

OLD_UNDEF = '''
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

OLD_BRK_CAP = '''	if (star_traplog_enabled && star_traplog_count < 200) {
		star_traplog_count++;
		char note[160];
		snprintf(note, sizeof(note),
		    "\\nStarTrapLog: brk tid %llu pc 0x%llx label 0x%x\\n",'''
NEW_BRK_CAP = '''	if (star_traplog_enabled && star_traplog_brk_count < 500) {
		star_traplog_brk_count++;
		char note[160];
		snprintf(note, sizeof(note),
		    "\\nStarTrapLog: brk tid %llu pc 0x%llx label 0x%x\\n",'''

OLD_VAR = "static uint32_t star_traplog_count;"
NEW_VAR = "static uint32_t star_traplog_brk_count;"

PATCHES = [
    ("undef-off", OLD_UNDEF, "", "\0never-present\0"),
    ("var", OLD_VAR, NEW_VAR, "star_traplog_brk_count"),
    ("brk-cap", OLD_BRK_CAP, NEW_BRK_CAP, "star_traplog_brk_count < 500"),
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
        bak = S + ".s80.bak"
        if not os.path.exists(bak):
            shutil.copy2(S, bak)
            print(f"[backup] {bak}")
        with open(S, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] sleh.c")
    print("done")


if __name__ == "__main__":
    main()
