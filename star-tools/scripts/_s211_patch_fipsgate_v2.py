#!/usr/bin/env python3
# v2 FIPS gate: revert to pre-patch, then apply a race-safe gate.
#   - Any time a trap comes from cc_fips_test: mark state=1, push the deadline
#     20s into the future, never rewrite.
#   - state==1 and (now >= deadline) and current proc is NOT cc_fips: open gate.
#   - Otherwise (state 0, or state 1 but still within grace): don't rewrite.
# The 20s grace covers the whole FIPS POST (~5s) plus ample margin, and being
# state-1-with-deadline means a concurrent background trap cannot open the gate
# early while the POST is still running.
import sys, shutil

P = "/root/star26/star-native/osfmk/arm64/sleh.c"
PRE = P + ".s211-pre"

# revert to the pre-s211 state first
shutil.copyfile(PRE, P)
src = open(P, "r", encoding="utf-8").read()
print("reverted to", PRE)

edits = []

# --- 1) include clock.h (for clock_interval_to_deadline / NSEC_PER_SEC) ---
old0 = "#include <kern/debug.h>"
new0 = "#include <kern/clock.h>\n#include <kern/debug.h>"
edits.append(("include clock.h", old0, new0))

# --- 2) state vars + helper after pac_patch_enabled block ---
old1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;"""
new1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;

/*
 * Boot FIPS gate.  corecrypto.dylib's __TEXT is validated by the "fips" boot
 * task (cc_fips_test) against an embedded MAC.  Rewriting RETAA there before
 * that check makes it fail (-74) and cc_fips_test never returns, so launchd
 * hangs at the fips boot task and the desktop never comes up.  Keep every page
 * pristine until the POST has finished; only then start rewriting.
 *
 * state: 0 = before fips, 1 = fips running (in grace), 2 = gate open.
 * Each cc_fips_test trap pushes a 20s deadline, so concurrent background
 * processes cannot open the gate while the POST is still in flight.
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

# --- 3) gate insertion inside pac_patch_page ---
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
		extern void proc_selfname(char *buf, int size);
		char comm[64];

		proc_selfname(comm, sizeof(comm));
		if (pac_name_has_cc_fips(comm)) {
			/* FIPS POST in flight: keep pages pristine, arm the grace. */
			pac_fips_state = 1;
			clock_interval_to_deadline(20, NSEC_PER_SEC,
			    &pac_fips_deadline);
			return;
		}
		if (pac_fips_state == 1 &&
		    mach_absolute_time() >= pac_fips_deadline) {
			pac_fips_state = 2;   /* POST done; rewriting now safe */
		} else {
			return;               /* before/during fips: no rewrite */
		}
	}

	task = current_task();"""
edits.append(("fips gate insert (v2)", old2, new2))

out = src
for name, old, new in edits:
    n = out.count(old)
    if n != 1:
        print(f"FAIL {name}: expected 1 match, got {n}")
        sys.exit(1)
    out = out.replace(old, new, 1)
    print(f"OK   {name}")

open(P + ".s211v1", "w", encoding="utf-8").write(src)
open(P, "w", encoding="utf-8").write(out)
print(f"DONE size {len(out)} (was {len(src)})")
