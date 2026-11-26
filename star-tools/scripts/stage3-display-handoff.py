#!/usr/bin/env python3
"""star-native stage 3: the loader <-> kernel framebuffer handoff contract.

Run after build-star-native-tree.py --reset, stage1-storage.py and
stage2-display-probe.py.  This writes code only.  It does NOT flash anything,
does NOT pack an image and does NOT write a single DPU register.

Why this stage exists
---------------------
The boot UI froze at 40% and the KERNEL BOOT CONSOLE card vanished on the
archived K90 line because that tree had no handoff contract at all:
MiniFramebufferFlip.inc used SM8750 DPU 12.0 offsets + a 0xFC800000 A/B
splash, took scan-out away from the loader, and never gave it back.

star / SM8350 is different in three measured ways:
  * ONE cont_splash_region at 0xEA600000 (iOS16 loader.c:907, star-B.dtb),
    already scanned out by the DPU when the kernel starts.  Nothing to flip.
  * loader v3 passes SCREEN.base/stride/width/height/depth into
    boot_args->Video (loader_05_layout_run_kernel.inc:578).  PE_state.video
    therefore already contains the truth.
  * PE_create_console() -> initialize_screen(..., kPEGraphicsMode) only MAPS
    that memory.  vc_initialize() computes rows/columns but does not erase the
    buffer, and gc_enable() is not reached until kPEAcquireScreen.  So the
    graphics console cannot wipe the loader's boot UI.

The second half of the 40% stall is not display hardware at all: loader v3's
ui_boot_milestones[] recognises ONLY K90 driver strings
(MiniIOMobileFramebuffer:, adreno8: step N, SM8750 LPASS, ...).  star-native
has none of those drivers, so no milestone can ever match and the byte_pct
fallback (30 + len*68/263000, needs 270 KB to finish) barely moves.  The bar
sits at 40% forever while the kernel is in fact running fine.

What this stage adds (one variable: display ownership)
------------------------------------------------------
  * kernel: bsd/dev/star/star_display_handoff.c -- reads PE_state.video,
    validates it against the star truth, prints the contract via IOLog(),
    and emits "star: milestone <tag>" anchors at real bsd_init stages.
    Ownership deliberately STAYS with the loader: this tree still has no
    kernel display service, so stopping the loader's drawing would hide the
    boot log again.  star_display_claim() is reserved for the future first
    WindowServer frame and is intentionally not called yet.
  * loader: ui_font_private.h gains star-native milestone anchors (45/52/75/98
    and a reserved 100+stop window-server one).  UI_BOOT.done, set by that
    final stop anchor, is v3's equivalent of iOS16's fb_stop().
  * loader: the boot_args->Video block gets the written-down contract comment.

IOLog() is mandatory: CONFIG_NO_PRINTF_STRINGS turns printf() into a no-op
that also strips the format string at preprocessing time (see
config/MASTER:309 and osfmk/kern/misc_protos.h:192).
"""
import argparse
import os
import shutil

DST = "/root/star26/star-native"
LDR = "/root/star26/hackios-xnu-kernel/xnuloader"

HANDOFF_C = r'''/*
 * star_display_handoff.c -- loader/kernel framebuffer ownership contract for
 * the Xiaomi 11 Ultra (star / SM8350).
 *
 * iOS16's star loader hands the framebuffer over explicitly
 * (loader.c:3887: fb_stop(), "from here the framebuffer belongs to the
 * kernel").  The iOS26 K90 tree had no such contract: it flipped a
 * newer-generation DPU register set for an SoC this phone does not have,
 * and took scan-out away from
 * the loader, freezing the boot UI at 40% and hiding the console card.
 *
 * star has ONE cont_splash_region at 0xEA600000, already being scanned out.
 * There is nothing to flip.  Until a real kernel display service exists the
 * loader is the ONLY code that can draw, so the correct contract is:
 *   - the loader keeps drawing (boot UI, progress bar, console card);
 *   - the kernel reads PE_state.video for information only, and promises
 *     never to clear, write, clock-flip or otherwise touch scan-out;
 *   - ownership moves ONLY when that future service produces its first frame
 *     (star_display_claim(), deliberately not called anywhere yet).
 *
 * This file NEVER writes a device register and NEVER writes the framebuffer.
 * All output goes through IOLog(): CONFIG_NO_PRINTF_STRINGS makes the
 * printf family a no-op that also discards format strings at preprocessing
 * time.
 *
 * Verified in this tree: PE_create_console() calls
 * initialize_screen(&PE_state.video, kPEGraphicsMode); vc_initialize() only
 * computes rows/columns and does not erase the buffer, and gc_enable() is not
 * called until kPEAcquireScreen.  v_display=1 (the default unless the payload
 * cmdline carries -v) keeps kernel text off the screen; the boot log is
 * visible in the loader's KERNEL BOOT CONSOLE card instead.
 */
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/types.h>
#include <pexpert/pexpert.h>

extern void IOLog(const char *format, ...);

#define STAR_SPLASH_PHYS    0xEA600000ULL
#define STAR_PANEL_WIDTH    1440U
#define STAR_PANEL_HEIGHT   3200U
#define STAR_PANEL_STRIDE   (STAR_PANEL_WIDTH * 4U)     /* 5760 */

#define STAR_FB_OWNER_LOADER 0
#define STAR_FB_OWNER_KERNEL 1

/* Starts at LOADER on purpose: nothing in this tree can draw a frame yet. */
static int star_fb_owner = STAR_FB_OWNER_LOADER;

int
star_display_owner(void)
{
	return star_fb_owner;
}

/* Reserved for the future WindowServer / IOMobileFramebuffer first frame.
 * NOT called anywhere in stage 3.  Flipping ownership early is exactly the
 * mistake that hid the boot console on the archived K90 line. */
void
star_display_claim(void)
{
	star_fb_owner = STAR_FB_OWNER_KERNEL;
	IOLog("star_display: ownership moved to the kernel (first frame)\n");
}

/* These lines are ALSO the milestone anchors for loader v3's progress bar.
 * The old table only recognised K90 driver strings, none of which this tree
 * can emit, so the bar could never move past 40%. */
void
star_display_milestone(const char *tag)
{
	IOLog("star: milestone %s\n", tag);
}

void
star_display_handoff(void)
{
	unsigned long base    = PE_state.video.v_baseAddr;
	unsigned long stride  = PE_state.video.v_rowBytes;
	unsigned long width   = PE_state.video.v_width;
	unsigned long height  = PE_state.video.v_height;
	unsigned long depth   = PE_state.video.v_depth;
	unsigned long display = PE_state.video.v_display;

	IOLog("star_display: handoff base=0x%lx stride=%lu %lux%lu depth=%lu graphics=%lu\n",
	    base, stride, width, height, depth, display);
	IOLog("star_display: star truth = single cont_splash_region 0xEA600000, %ux%u stride %u (no A/B)\n",
	    STAR_PANEL_WIDTH, STAR_PANEL_HEIGHT, STAR_PANEL_STRIDE);
	if (base == STAR_SPLASH_PHYS && stride == STAR_PANEL_STRIDE &&
	    width == STAR_PANEL_WIDTH && height == STAR_PANEL_HEIGHT) {
		IOLog("star_display: boot-args video MATCHES the star panel\n");
	} else {
		IOLog("star_display: boot-args video DIFFERS from the star truth; the loader's own values are used\n");
	}
	IOLog("star_display: owner=loader; kernel does NOT clear, flip clocks or take scan-out\n");
	IOLog("star_display: graphics console only maps the splash (vc_initialize does not erase it)\n");
	star_display_milestone("handoff");
}
'''

DISPLAY_H = r'''#ifndef _SYS_STAR_DISPLAY_H_
#define _SYS_STAR_DISPLAY_H_

/* Read-only SM8350 display survey; enabled by boot-arg star_display_probe=1. */
void star_display_probe(void);

/* Loader/kernel framebuffer ownership contract; no register writes, ever. */
void star_display_handoff(void);
void star_display_milestone(const char *tag);
int  star_display_owner(void);
void star_display_claim(void);

#endif /* _SYS_STAR_DISPLAY_H_ */
'''

MILESTONES_OLD = '''	{ "MiniIOMobileFramebuffer: swap ",     100, "Handing display to iOS WindowServer...",           1 },
};
'''

MILESTONES_NEW = '''	{ "MiniIOMobileFramebuffer: swap ",     100, "Handing display to iOS WindowServer...",           1 },

	/* --- star-native (SM8350) milestones --------------------------------
	 * The star-native kernel has no K90 drivers, so none of the strings
	 * above can ever appear in its live log.  Without these anchors the
	 * bar stalls at 40% (the byte_pct fallback needs 270 KB of log before
	 * it reaches 100).  bsd/dev/star/star_display_handoff.c and
	 * bsd/kern/bsd_init.c emit these through IOLog(), the channel that
	 * actually reaches the loader's live log / console card.
	 *
	 * The last anchor is RESERVED for the future WindowServer first frame.
	 * It is not emitted yet: until a kernel display service exists, the
	 * loader keeps drawing and the console card keeps updating.  When that
	 * anchor finally arrives UI_BOOT.done=1, which is this loader's
	 * equivalent of iOS16's fb_stop(). */
	{ "star: milestone storage",            45, "star: UFS storage & disk tree published...",        0 },
	{ "star: milestone handoff",            52, "star: framebuffer handoff (loader keeps scan-out)...", 0 },
	{ "star: milestone root-mounted",       75, "Mounting the star system volume...",                 0 },
	{ "star: milestone launchd",            98, "Starting launchd on star / SM8350...",              0 },
	{ "star: milestone window-server",     100, "Handing display to iOS WindowServer...",            1 },
};
'''

VIDEO_OLD = '''	/* any display the firmware has set up: the phone's panel, or QEMU's ramfb */
	if (SCREEN.base != 0) {
'''

# An earlier draft worded the contract comment differently.  If a tree carries
# that copy too, drop it so repeated runs cannot stack duplicates.
LEGACY_VIDEO_NEW = '''	/* --- star framebuffer handoff contract -------------------------------
	 * star / SM8350 has ONE cont_splash_region at 0xEA600000 which the DPU
	 * already scans out.  There is no A/B pair and no DPU 12.0 flip.  We
	 * pass SCREEN.* straight into boot_args->Video; the kernel's graphics
	 * console only maps that memory and does not erase it, so the boot UI,
	 * the progress bar and the KERNEL BOOT CONSOLE card stay visible while
	 * the kernel runs.  Ownership stays with the loader until a kernel
	 * display service emits its first frame (star: milestone window-server,
	 * which sets UI_BOOT.done -- v3's fb_stop() equivalent).
	 * See bsd/dev/star/star_display_handoff.c in star-native. */
'''

VIDEO_NEW = '''	/* --- star framebuffer handoff contract -------------------------------
	 * star / SM8350 has ONE cont_splash_region at 0xEA600000 which the DPU
	 * already scans out.  There is no A/B pair and nothing to flip.  We
	 * pass SCREEN.* straight into boot_args->Video; the kernel's graphics
	 * console only maps that memory and does not erase it, so the boot UI,
	 * the progress bar and the KERNEL BOOT CONSOLE card stay visible while
	 * the kernel runs.  Ownership stays with the loader until a kernel
	 * display service emits its first frame (star: milestone window-server,
	 * which sets UI_BOOT.done -- v3's fb_stop() equivalent).
	 * See bsd/dev/star/star_display_handoff.c in star-native. */
	/* any display the firmware has set up: the phone's panel, or QEMU's ramfb */
	if (SCREEN.base != 0) {
'''


def path(root, rel):
    return os.path.join(root, rel)


def read(root, rel):
    with open(path(root, rel), errors="replace") as fh:
        return fh.read()


def write(root, rel, text):
    full = path(root, rel)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as fh:
        fh.write(text)


def backup(root, rel):
    src, dst = path(root, rel), path(root, rel + ".pre-stage3")
    if not os.path.exists(dst):
        shutil.copyfile(src, dst)


def replace(root, rel, old, new, count=1):
    text = read(root, rel)
    # Several edits extend a line rather than replacing it, so `old` is still
    # present after a successful run.  Detect the applied state first.
    if new in text:
        print("  %-46s already applied" % rel)
        return
    got = text.count(old)
    if got != count:
        raise SystemExit("EDIT FAILED %s: expected %d, got %d of %r" %
                         (rel, count, got, old[:80]))
    backup(root, rel)
    write(root, rel, text.replace(old, new))
    print("  %-46s %d edit(s)" % (rel, got))


CHECKS = [
    (DST, "bsd/dev/star/star_display_handoff.c", "star_display_handoff", 2, 1),
    (DST, "bsd/dev/star/star_display_handoff.c", "0xEA600000", 1, 1),
    (DST, "bsd/dev/star/star_display_handoff.c", "star: milestone %s", 1, 1),
    (DST, "bsd/dev/star/star_display_handoff.c", "PE_state.video.v_baseAddr", 1, 1),
    (DST, "bsd/dev/star/star_display_handoff.c", "IOLog(", 7, 1),
    (DST, "bsd/dev/star/star_display_handoff.c", "ml_io_map", 0, 0),
    (DST, "bsd/dev/star/star_display_handoff.c", "0xFC800000", 0, 0),
    (DST, "bsd/dev/star/star_display_handoff.c", "DPU 12.0", 0, 0),
    (DST, "bsd/dev/star/star_display_handoff.c", "printf(", 0, 0),
    (DST, "bsd/sys/star_display.h", "star_display_claim", 1, 1),
    (DST, "bsd/conf/files", "star_display_handoff.c", 1, 1),
    (DST, "bsd/kern/bsd_init.c", "star_display_handoff();", 1, 1),
    (DST, "bsd/kern/bsd_init.c", 'star_display_milestone("storage")', 1, 1),
    (DST, "bsd/kern/bsd_init.c", 'star_display_milestone("root-mounted")', 1, 1),
    (DST, "bsd/kern/bsd_init.c", 'star_display_milestone("launchd")', 1, 1),
    (LDR, "ui_font_private.h", "star: milestone storage", 1, 1),
    (LDR, "ui_font_private.h", "star: milestone handoff", 1, 1),
    (LDR, "ui_font_private.h", "star: milestone root-mounted", 1, 1),
    (LDR, "ui_font_private.h", "star: milestone launchd", 1, 1),
    (LDR, "ui_font_private.h", "star: milestone window-server", 1, 1),
    (LDR, "ui_font_private.h", "fb_stop()", 1, 1),
    (LDR, "loader_05_layout_run_kernel.inc", "star framebuffer handoff contract", 1, 1),
]


def check_only():
    print("=== stage 3 CHECK (read-only) ===")
    bad = 0
    for root, rel, token, want, mode in CHECKS:
        text = read(root, rel)
        got = text.count(token)
        ok = (got == 0) if mode == 0 else (got >= want)
        if not ok:
            bad += 1
        print("  %-4s %-42s %-38s %d (want %s%d)" %
              ("OK" if ok else "FAIL", rel, token, got,
               "0" if mode == 0 else ">=", want))
    if bad:
        raise SystemExit("stage 3 check failed: %d mismatch(es)" % bad)
    print("DONE")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="verify only, change nothing")
    args = ap.parse_args()
    if args.check:
        check_only()
        return

    print("=== stage 3: star loader/kernel framebuffer handoff ===")
    ldr_inc = "loader_05_layout_run_kernel.inc"
    txt = read(LDR, ldr_inc)
    if LEGACY_VIDEO_NEW in txt:
        backup(LDR, ldr_inc)
        write(LDR, ldr_inc, txt.replace(LEGACY_VIDEO_NEW, ""))
        print("  removed a stale duplicate of the handoff contract comment")
    write(DST, "bsd/dev/star/star_display_handoff.c", HANDOFF_C)
    print("  wrote bsd/dev/star/star_display_handoff.c (%d bytes)" % len(HANDOFF_C))
    backup(DST, "bsd/sys/star_display.h")
    write(DST, "bsd/sys/star_display.h", DISPLAY_H)

    replace(DST, "bsd/conf/files",
            "bsd/dev/star/star_display_probe.c\tstandard\n",
            "bsd/dev/star/star_display_probe.c\tstandard\n"
            "bsd/dev/star/star_display_handoff.c\tstandard\n")

    replace(DST, "bsd/kern/bsd_init.c",
            "\t\tstar_display_probe();             /* read-only, gated by star_display_probe=1 */\n",
            "\t\tstar_display_probe();             /* read-only, gated by star_display_probe=1 */\n"
            "\t\tstar_display_handoff();           /* ownership contract, zero writes */\n"
            "\t\tstar_display_milestone(\"storage\");\n")
    replace(DST, "bsd/kern/bsd_init.c",
            "\tIOSecureBSDRoot(rootdevice);\n",
            "\tstar_display_milestone(\"root-mounted\");\n"
            "\tIOSecureBSDRoot(rootdevice);\n")
    replace(DST, "bsd/kern/bsd_init.c",
            "\tload_init_program(p);\n",
            "\tstar_display_milestone(\"launchd\");\n"
            "\tload_init_program(p);\n")

    replace(LDR, "ui_font_private.h", MILESTONES_OLD, MILESTONES_NEW)
    replace(LDR, "loader_05_layout_run_kernel.inc", VIDEO_OLD, VIDEO_NEW)

    print("=== validation ===")
    check_only()


if __name__ == "__main__":
    main()
