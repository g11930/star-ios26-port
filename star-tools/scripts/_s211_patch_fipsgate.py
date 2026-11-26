#!/usr/bin/env python3
# Add a boot-phase "FIPS gate" to pac_patch_page:
#   - before the "fips" boot task (cc_fips_test) has run: never rewrite pages,
#     so corecrypto.dylib keeps its original bytes and the FIPS integrity MAC
#     matches (otherwise boot task hangs -> no desktop).
#   - after cc_fips_test has come and gone: rewrite normally (speedup).
# Boot-arg pac_patch_fips=0 disables the gate (old s210 behaviour) for A/B.
import sys

P = "/root/star26/star-native/osfmk/arm64/sleh.c"
src = open(P, "r", encoding="utf-8").read()

edits = []

# --- 1) state vars + helper, right after pac_patch_enabled block ---
old1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;"""
new1 = """static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;

/*
 * Boot FIPS gate.  corecrypto.dylib's __TEXT is validated by the "fips" boot
 * task (cc_fips_test) against an embedded MAC.  Rewriting RETAA there before
 * that check makes it fail with -74 and launchd never finishes boot.  So keep
 * every page pristine until cc_fips_test has come and gone; only then start
 * rewriting, which is what actually speeds up the desktop.
 *
 * state: 0 = before fips (no rewrite), 1 = fips process seen (no rewrite),
 *        2 = fips finished (rewrite enabled).
 * Boot-arg pac_patch_fips=0 disables the gate for A/B comparison.
 */
static int      pac_patch_fips = -1;   /* -1 = lazy-init */
static int      pac_fips_state;

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

# --- 2) gate insertion inside pac_patch_page, right after enabled check ---
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
		/* corecrypto's code pages must stay byte-identical until the FIPS
		 * POST has validated them. */
		extern void proc_selfname(char *buf, int size);
		char comm[64];
		proc_selfname(comm, sizeof(comm));
		if (pac_name_has_cc_fips(comm)) {
			pac_fips_state = 1;
			return;
		}
		if (pac_fips_state == 1) {
			pac_fips_state = 2;   /* fips process gone -> enable rewriting */
		} else {
			return;               /* before fips: keep everything pristine */
		}
	}

	task = current_task();"""
edits.append(("fips gate insert", old2, new2))

out = src
for name, old, new in edits:
    n = out.count(old)
    if n != 1:
        print(f"FAIL {name}: expected 1 match, got {n}")
        sys.exit(1)
    out = out.replace(old, new, 1)
    print(f"OK   {name}")

open(P + ".s211-pre", "w", encoding="utf-8").write(src)
open(P, "w", encoding="utf-8").write(out)
print(f"DONE backup -> {P}.s211-pre")
print(f"new size {len(out)} (was {len(src)})")
