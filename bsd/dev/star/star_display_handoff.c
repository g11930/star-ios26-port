/*
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
 * All output goes through star_log(): CONFIG_NO_PRINTF_STRINGS makes the
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

#include <stdarg.h>

extern void loader_log_line(const char *line);

/*
 * The loader's log ring is the only channel in this boot that produces text:
 * IOLog is undefined-weak in this build (see the file comment), and
 * CONFIG_NO_PRINTF_STRINGS discards printf's format strings outright.
 * loader_log_line() is lock-protected, masks interrupts itself, and appends
 * one complete line, which is exactly what the loader's live console card
 * parses and what the logdump partition keeps.
 */
/*
 * P0: emit the format string itself as a static literal.  No vsnprintf: an
 * empty formatted line makes loader_log_line() append nothing at all, which is
 * exactly what checkpoint 14 reported ("0 bytes").  Every call site keeps its
 * own distinctive text, so the milestones remain identifiable.
 */
static void
star_log(const char *format, ...)
{
	loader_log_line("\nSTARL ");
	loader_log_line(format);
	loader_log_line("\n");
}

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
	star_log("star_display: ownership moved to the kernel (first frame)\n");
}

/* These lines are ALSO the milestone anchors for loader v3's progress bar.
 * The old table only recognised K90 driver strings, none of which this tree
 * can emit, so the bar could never move past 40%. */
void
star_display_milestone(const char *tag)
{
	loader_log_line("\nstar: milestone ");
	loader_log_line(tag);
	loader_log_line("\n");
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

	star_log("star_display: handoff base=0x%lx stride=%lu %lux%lu depth=%lu graphics=%lu\n",
	    base, stride, width, height, depth, display);
	star_log("star_display: star truth = single cont_splash_region 0xEA600000, %ux%u stride %u (no A/B)\n",
	    STAR_PANEL_WIDTH, STAR_PANEL_HEIGHT, STAR_PANEL_STRIDE);
	if (base == STAR_SPLASH_PHYS && stride == STAR_PANEL_STRIDE &&
	    width == STAR_PANEL_WIDTH && height == STAR_PANEL_HEIGHT) {
		star_log("star_display: boot-args video MATCHES the star panel\n");
	} else {
		star_log("star_display: boot-args video DIFFERS from the star truth; the loader's own values are used\n");
	}
	star_log("star_display: owner=loader; kernel does NOT clear, flip clocks or take scan-out\n");
	star_log("star_display: graphics console only maps the splash (vc_initialize does not erase it)\n");
	star_display_milestone("handoff");
}
