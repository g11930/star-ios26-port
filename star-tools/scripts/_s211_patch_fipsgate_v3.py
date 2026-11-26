#!/usr/bin/env python3
# v3 FIPS gate: revert, then apply an efficient, race-safe gate.
#   Hot path (the vast majority of traps) must be ONE clock read.
#   - state 1 and now < deadline  -> return (in grace, no rewrite). Cheap.
#   - otherwise sample the proc name every 1024 traps:
#       * is cc_fips_test -> state=1, deadline = now+20s, return.
#       * state was 1 and grace expired and not fips -> state=2 (open).
#       * state 0 and not fips -> stay 0, return (no rewrite before fips).
#   20s grace >> FIPS POST (~7s observed), and each fips trap re-arms it, so a
#   concurrent background trap can never open the gate mid-POST.
import sys, shutil

P = "/root/star26/star-native/osfmk/arm64/sleh.c"
PRE = P + ".s211-pre"

shutil.copyfile(PRE, P)
src = open(P, "r", encoding="utf-8").read()
print("reverted to", PRE)

edits = []

old0 = "#include <kern/debug.h>"
new0 = "#include <kern/clock.h>\n#include <kern/debug.h>"
edits.append(("include clock.h", old0, new0))

old1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;"""
new1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;

/*
 * Boot FIPS gate.  corecrypto.dylib's __TEXT is validated by the "fips" boot
 * task (cc_fips_test) against an embedded MAC.  Rewriting RETAA in those pages
 * before the check makes it fail (-74); cc_fips_test then never returns and
 * launchd hangs at the fips boot task, so the desktop never comes up.  Keep
 * every page pristine until the POST has finished, then rewrite as usual.
 *
 * state: 0 = before fips, 1 = fips seen (in grace), 2 = gate open.
 * Every cc_fips_test trap re-arms a 20s deadline, so concurrent background
 * traps cannot open the gate while the POST is still running.  The hot path
 * only reads the clock; the (comparatively costly) proc-name probe runs at
 * most once per 1024 traps.
 * Boot-arg pac_patch_fips=0 disables the gate for A/B comparison.
 */
static int      pac_patch_fips = -1;   /* -1 = lazy-init */
static int      pac_fips_state;
static uint64_t pac_fips_deadline;

static bool
pac_name_has_cc_fips(const char *s)
{
	static const char needle[] = "cc_fips";
	const size_t nl = sizeof(needle) - 1;

	if (s == NULL) {
		return false;
	}
	while (*s != '\\0') {
		size_t i = 0;
		while (i < nl && s[i] != '\\0' && s[i] == needle[i]) {
			i++;
		}
		if (i == nl) {
			return true;
		}
		s++;
	}
	return false;
}"""
edits.append(("state vars + helper", old1, new1))

old2 = """	if (pac_patch_enabled == 0) {
		return;
	}

	task = current_task();"""
new2 = """	if (pac_patch_enabled == 0) {
		return;
	}

	if (__improbable(pac_patch_fips < 0)) {
		uint32_t v = 1;
		(void) PE_parse_boot_argn("pac_patch_fips", &v, sizeof(v));
		pac_patch_fips = v ? 1 : 0;
	}
	if (pac_patch_fips != 0 && pac_fips_state != 2) {
		if (pac_fips_state == 1 &&
		    mach_absolute_time() < pac_fips_deadline) {
			return;   /* inside the post-fips grace window */
		}
		if ((pac_emu_hits & 0x3ffu) == 0) {
			extern void proc_selfname(char *buf, int size);
			char comm[64];

			proc_selfname(comm, sizeof(comm));
			if (pac_name_has_cc_fips(comm)) {
				pac_fips_state = 1;
				clock_interval_to_deadline(20, NSEC_PER_SEC,
				    &pac_fips_deadline);
				return;
			}
			if (pac_fips_state == 1) {
				pac_fips_state = 2;   /* POST done: open the gate */
			}
		}
		if (pac_fips_state != 2) {
			return;           /* before/during fips: no rewrite */
		}
	}

	task = current_task();"""
edits.append(("fips gate insert (v3)", old2, new2))

out = src
for name, old, new in edits:
    n = out.count(old)
    if n != 1:
        print(f"FAIL {name}: expected 1 match, got {n}")
        sys.exit(1)
    out = out.replace(old, new, 1)
    print(f"OK   {name}")

open(P + ".s211v2", "w", encoding="utf-8").write(src)
open(P, "w", encoding="utf-8").write(out)
print(f"DONE size {len(out)} (was {len(src)})")
