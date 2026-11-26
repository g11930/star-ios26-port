#!/usr/bin/env python3
# s221 PAC subsystem rewrite.  Applied to /root/star26/star-native/osfmk/arm64/sleh.c
# Backup already made as sleh.c.s221-pre-rewrite.
import sys

P = "/root/star26/star-native/osfmk/arm64/sleh.c"
s = open(P, "r", encoding="utf-8").read()
orig = s

def rep(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        print("FAIL [%s]: expected 1 match, got %d" % (label, n)); sys.exit(1)
    s = s.replace(old, new, 1)
    print("OK   [%s]" % label)

# ---------------------------------------------------------------------------
# 1. Config struct + helpers after the FIPS state variables.
# ---------------------------------------------------------------------------
rep(
"""static int      pac_patch_fips = -1;   /* -1 = lazy-init */
static int      pac_fips_state;
static uint64_t pac_fips_deadline;
""",
"""static int      pac_patch_fips = -1;   /* -1 = lazy-init */
static int      pac_fips_state;
static uint64_t pac_fips_deadline;

/*
 * Rewritten PAC subsystem configuration (s221).
 *
 * The original design rewrote a page synchronously on the very first trap
 * that touched it.  During cold boot that meant scanning and flushing ~2800
 * pages while launchd/SpringBoard were starting, which stretched an otherwise
 * working 10-minute boot (s217) past 19 minutes without reaching the desktop
 * (s220).  Rewrite is now gated by three independent, measurable limits:
 *
 *   delay  - rewrite_deadline is armed on the first trap; no page is touched
 *            until N seconds have passed.  Startup-only pages never trap
 *            again, so waiting filters them out with no per-page bookkeeping.
 *   budget - hard cap on total pages rewritten across the whole session.
 *   burst  - max pages rewritten per 256k-trap window, so a single burst of
 *            first-touch traps cannot stall a render pipeline.
 *
 * New boot-args (optional; defaults disable rewrite until pac_patch opts in):
 *   pac_patch_delay=<sec>    default 900   (15 min, past unlock/desktop)
 *   pac_patch_budget=<pages> default 256
 *   pac_patch_burst=<pages>  default 8
 * pac_patch=<mask> and pac_patch_fips keep their existing meaning.
 */
struct star_pac_config {
	uint64_t rewrite_deadline;   /* absolute Mach time; armed on first trap */
	uint32_t delay_secs;
	uint32_t page_budget;
	uint32_t burst;
	uint32_t burst_used;         /* pages rewritten in current window */
	bool     rewrite_open_logged;
};
static struct star_pac_config pac_cfg = {
	.rewrite_deadline = 0,
	.delay_secs = 900,
	.page_budget = 256,
	.burst = 8,
	.burst_used = 0,
	.rewrite_open_logged = false,
};
static bool pac_cfg_loaded;

static void
pac_load_config(void)
{
	uint32_t v;

	if (__improbable(!pac_cfg_loaded)) {
		pac_cfg_loaded = true;

		v = 900;
		(void)PE_parse_boot_argn("pac_patch_delay", &v, sizeof(v));
		pac_cfg.delay_secs = v;

		v = 256;
		(void)PE_parse_boot_argn("pac_patch_budget", &v, sizeof(v));
		pac_cfg.page_budget = v;

		v = 8;
		(void)PE_parse_boot_argn("pac_patch_burst", &v, sizeof(v));
		pac_cfg.burst = v;
	}
}

/* True once rewrite is enabled, past its deadline, and within budget. */
static inline bool
pac_rewrite_allowed(void)
{
	if (pac_patch_enabled <= 0) {
		return false;
	}
	if (pac_cfg.rewrite_deadline == 0) {
		/* Arm on first trap: now + delay_secs. */
		clock_interval_to_deadline(pac_cfg.delay_secs, NSEC_PER_SEC,
		    &pac_cfg.rewrite_deadline);
		return false;
	}
	if (mach_absolute_time() < pac_cfg.rewrite_deadline) {
		return false;
	}
	if (pac_patch_pages >= pac_cfg.page_budget) {
		return false;
	}
	return true;
}
""",
"insert config struct + gates")

# ---------------------------------------------------------------------------
# 2. Refit pac_patch_page entry: new config, gates, gate-open IOLog.
# ---------------------------------------------------------------------------
rep(
"""	if (__improbable(pac_patch_enabled < 0)) {
		uint32_t v = 0;   /* default: pure emulation; cmdline opts in */
		(void) PE_parse_boot_argn("pac_patch", &v, sizeof(v));
		pac_patch_enabled = (int)(v & 0xfu);
	}
	if (pac_patch_enabled == 0) {
		return;
	}

	if (__improbable(pac_patch_fips < 0)) {""",
"""	if (__improbable(pac_patch_enabled < 0)) {
		uint32_t v = 0;   /* default: pure emulation; cmdline opts in */
		(void) PE_parse_boot_argn("pac_patch", &v, sizeof(v));
		pac_patch_enabled = (int)(v & 0xfu);
		pac_load_config();
	}
	if (!pac_rewrite_allowed()) {
		return;
	}
	if (__improbable(!pac_cfg.rewrite_open_logged)) {
		char note[160];
		pac_cfg.rewrite_open_logged = true;
		snprintf(note, sizeof(note),
		    "\\npac: rewrite gate OPEN delay=%us budget=%u burst=%u\\n",
		    pac_cfg.delay_secs, pac_cfg.page_budget, pac_cfg.burst);
		loader_log_line(note);
	}

	if (__improbable(pac_patch_fips < 0)) {""",
"pac_patch_page gate refit")

# ---------------------------------------------------------------------------
# 3. FIPS hot path: single clock read, gate remains correct.
# ---------------------------------------------------------------------------
rep(
"""	if (pac_patch_fips != 0 && pac_fips_state != 2) {
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
	}""",
"""	if (pac_patch_fips != 0 && pac_fips_state != 2) {
		/* state 1: 20s grace after last cc_fips trap.  One clock read. */
		if (pac_fips_state == 1) {
			if (mach_absolute_time() < pac_fips_deadline) {
				return;
			}
			pac_fips_state = 2;       /* grace expired: POST done */
		} else if ((pac_emu_hits & 0x3ffu) == 0) {
			extern void proc_selfname(char *buf, int size);
			char comm[64];

			proc_selfname(comm, sizeof(comm));
			if (pac_name_has_cc_fips(comm)) {
				pac_fips_state = 1;
				clock_interval_to_deadline(20, NSEC_PER_SEC,
				    &pac_fips_deadline);
			}
			return;   /* gated until POST grace expires */
		} else {
			return;   /* before fips: no rewrite */
		}
	}""",
"FIPS hot path slim")

# ---------------------------------------------------------------------------
# 4. Burst limiter before the write loop.
# ---------------------------------------------------------------------------
rep(
"""	insns = (uint32_t *)phystokv(ptoa(pp));
	if (insns == NULL) {
		return;
	}

	for (unsigned int i = 0; i < PAGE_SIZE / sizeof(uint32_t); i++) {""",
"""	insns = (uint32_t *)phystokv(ptoa(pp));
	if (insns == NULL) {
		return;
	}

	/* Bounded work per observation window: spread icache-flush cost so a
	 * single burst of first-touch traps cannot stall a render pipeline. */
	if (pac_cfg.burst_used >= pac_cfg.burst) {
		return;
	}
	pac_cfg.burst_used++;

	for (unsigned int i = 0; i < PAGE_SIZE / sizeof(uint32_t); i++) {""",
"burst limiter")

# ---------------------------------------------------------------------------
# 5. Stat line: replenish burst, show budget/gate state.
# ---------------------------------------------------------------------------
rep(
"""	if (__improbable((pac_emu_hits & 0x3ffffu) == 0)) {
		char stat[144];
		snprintf(stat, sizeof(stat),
		    "\\npac: traps=%llu pages=%llu instrs=%llu\\n",
		    (unsigned long long)pac_emu_hits,
		    (unsigned long long)pac_patch_pages,
		    (unsigned long long)pac_patch_instrs);
		loader_log_line(stat);
	}""",
"""	if (__improbable((pac_emu_hits & 0x3ffffu) == 0)) {
		char stat[176];
		pac_cfg.burst_used = 0;   /* replenish once per 256k traps */
		snprintf(stat, sizeof(stat),
		    "\\npac: traps=%llu pages=%llu/%u instrs=%llu gate=%d\\n",
		    (unsigned long long)pac_emu_hits,
		    (unsigned long long)pac_patch_pages,
		    pac_cfg.page_budget,
		    (unsigned long long)pac_patch_instrs,
		    pac_cfg.rewrite_open_logged ? 1 : 0);
		loader_log_line(stat);
	}""",
"stat line + burst replenish")

if s == orig:
    print("FAIL: no changes made"); sys.exit(1)

open(P, "w", encoding="utf-8").write(s)
print("WROTE", P, "bytes", len(s), "delta", len(s)-len(orig))
