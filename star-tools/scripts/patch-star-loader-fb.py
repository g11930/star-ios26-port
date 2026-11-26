#!/usr/bin/env python3
"""Fix the star (Xiaomi 11 Ultra / SM8350) framebuffer truth in XNULOADER v3.

Evidence, all from THIS phone:
  * the running loader's own log (p38-staged.bin, line 3):
        display 1440 x 3200 at ea600000
        platform star
  * the iOS16-era star loader: HackiOS-Xiaomi11Ultra/xnuloader/loader.c:907
        .fb_base = 0xEA600000   /* cont_splash_region */
  * star-B.dtb: qcom,mdss_mdp@ae00000, one cont_splash region (no A/B pair)

What this patch changes (loader source only, no flashing):
  1. platform_private.h: platform_star.fb_base 0 -> 0xEA600000, with the
     measured geometry in the comment.  That makes GOP-less boots draw to the
     real panel memory and lets platforms[] identify star by fb_base.
  2. loader_06a_screen_ui.inc: ui_flush_splash_fb() gains a star branch that
     only cleans the dcache over the splash framebuffer.  star has ONE
     cont_splash region, so there is no second buffer to memcpy to (the K90
     0xfc800000 -> 0xfd400000 A/B copy stays, untouched, for the other phone).

Deliberately NOT changed: the `SCREEN.base != platform_annibale.fb_base`
guards around the PMK8550 SPMI buttons / reboot.  On star they correctly
return and keep K90 PMIC register writes off this phone; star reboots through
EfiResetCold.  Those guards get a comment saying so, no logic change.

Usage:
  python3 patch-star-loader-fb.py --check
  python3 patch-star-loader-fb.py --apply
  python3 patch-star-loader-fb.py --revert
"""
import argparse
import os
import shutil

LOADER = "/root/star26/hackios-xnu-kernel/xnuloader"
PLAT = "platform_private.h"
UI = "loader_06a_screen_ui.inc"
SPMI_BTN = "loader_06a_screen_ui.inc"
SPMI_REBOOT = "loader_spmi_reboot_private.h"

OLD_PLATFORM = """/*
 * star (Xiaomi 11 Ultra, SM8350): GIC and CPU topology read from the same-SoC venus device
 * tree (GIC dist 0x17a00000, redist 0x17a60000, stride 0x20000; eight cores MPIDR 0..0x700,
 * the four Cortex-A55 little cores at 0..0x300). DIRECT_PHONE_PLAT selects this platform
 * without a GOP match. Framebuffer base is confirmed on the real device and updated here.
 */
static const struct platform platform_star = {
\t.name = "star", .io_base = 0x00400000, .io_size = 0x3FC00000,
\t.gic_dist = 0x17a00000, .gic_redist = 0x17a60000,
\t.gic_redist_stride = 0x20000,
\t.uart = 0, .log_other_cpu = 1,
\t.cores = 8, .core_mpidr = {0, 0x100, 0x200, 0x300, 0x400, 0x500, 0x600, 0x700},
\t.small_cores = 0x0f,
\t.fb_base = 0,
};"""

NEW_PLATFORM = """/*
 * star (Xiaomi 11 Ultra, SM8350): GIC and CPU topology read from the same-SoC venus device
 * tree (GIC dist 0x17a00000, redist 0x17a60000, stride 0x20000; eight cores MPIDR 0..0x700,
 * the four Cortex-A55 little cores at 0..0x300). DIRECT_PHONE_PLAT selects this platform
 * without a GOP match.
 *
 * Framebuffer: 0xEA600000, 1440x3200, 5760 bytes a row, 32bpp -- the phone's one
 * cont_splash_region.  Measured on this device by the loader itself
 * ("display 1440 x 3200 at ea600000" / "platform star" in the boot log) and
 * independently recorded in the iOS16 star loader (loader.c:907).  There is NO
 * A/B splash pair on SM8350; the 0xFC800000/0xFD400000 scheme belongs to the
 * other phone's DPU 12.0 and must never be applied here.
 */
static const struct platform platform_star = {
\t.name = "star", .io_base = 0x00400000, .io_size = 0x3FC00000,
\t.gic_dist = 0x17a00000, .gic_redist = 0x17a60000,
\t.gic_redist_stride = 0x20000,
\t.uart = 0, .log_other_cpu = 1,
\t.cores = 8, .core_mpidr = {0, 0x100, 0x200, 0x300, 0x400, 0x500, 0x600, 0x700},
\t.small_cores = 0x0f,
\t.fb_base = 0xEA600000,
};"""

OLD_FLUSH = """static void
ui_flush_splash_fb(void)
{
\tif (skip_ufs_arbitration && SCREEN.base == 0xfc800000ULL) {
\t\tuint64_t bytes = (uint64_t)SCREEN.height * SCREEN.stride;
\t\tclean_dcache(SCREEN.base, SCREEN.base + bytes);
\t\tmemcpy((void *)(uintptr_t)0xfd400000ULL, (const void *)(uintptr_t)SCREEN.base, bytes);
\t\tclean_dcache(0xfd400000ULL, 0xfd400000ULL + bytes);
\t}
}"""

NEW_FLUSH = """static void
ui_flush_splash_fb(void)
{
\tif (SCREEN.base == 0) return;
\tuint64_t bytes = (uint64_t)SCREEN.height * SCREEN.stride;

\t/* star / SM8350: one cont_splash_region, and the DPU is already scanning
\t * it.  There is no second buffer to copy to; just make sure the last
\t * drawing the loader did reached memory before the kernel takes over.
\t * Judge by the framebuffer address, not PLAT: ui_init() can call this
\t * before the platform pointer has been assigned. */
\tif (SCREEN.base == platform_star.fb_base) {
\t\tclean_dcache(SCREEN.base, SCREEN.base + bytes);
\t\treturn;
\t}
\t/* The other phone's DPU 12.0 splash needs its A/B copy.  Not star. */
\tif (skip_ufs_arbitration && SCREEN.base == platform_annibale.fb_base) {
\t\tclean_dcache(SCREEN.base, SCREEN.base + bytes);
\t\tmemcpy((void *)(uintptr_t)0xfd400000ULL, (const void *)(uintptr_t)SCREEN.base, bytes);
\t\tclean_dcache(0xfd400000ULL, 0xfd400000ULL + bytes);
\t}
}"""

OLD_BTN_GUARD = "\tif (SCREEN.base != platform_annibale.fb_base) return;\n"
NEW_BTN_GUARD = ("\t/* star / SM8350 uses PMK8350, not PMK8550: leave this phone's PMIC alone\n"
                 "\t * and let EfiResetCold handle a reboot. */\n"
                 "\tif (SCREEN.base != platform_annibale.fb_base) return;\n")

OLD_RB_GUARD = "\tif (SCREEN.base != platform_annibale.fb_base) return 0;\n"
NEW_RB_GUARD = ("\t/* PMK8550 only.  star (PMK8350) reboots through EfiResetCold. */\n"
                "\tif (SCREEN.base != platform_annibale.fb_base) return 0;\n")


def path(name):
    return os.path.join(LOADER, name)


def read(name):
    with open(path(name), errors="replace") as fh:
        return fh.read()


def write(name, text):
    with open(path(name), "w") as fh:
        fh.write(text)


def backup(name):
    dst = path(name) + ".pre-star-fb"
    if not os.path.exists(dst):
        shutil.copy2(path(name), dst)


def restore(name):
    src = path(name) + ".pre-star-fb"
    if os.path.exists(src):
        shutil.copy2(src, path(name))
        print("  restored %s" % name)


def status():
    plat, ui, rb = read(PLAT), read(UI), read(SPMI_REBOOT)
    checks = [
        ("platform_star.fb_base = 0xEA600000", ".fb_base = 0xEA600000," in plat,
         ".fb_base = 0," in plat),
        ("star dcache-only splash flush", "if (SCREEN.base == platform_star.fb_base) {" in ui,
         "static void\nui_flush_splash_fb(void)" in ui),
        ("A/B copy now keyed by annibale fb_base", "SCREEN.base == platform_annibale.fb_base" in ui,
         "SCREEN.base == 0xfc800000ULL" in ui),
        ("K90 PMIC guards annotated (not removed)", "star / SM8350 uses PMK8350" in ui and
         "PMK8550 only" in rb, True),
    ]
    applied = sum(1 for _, new, _ in checks if new)
    print("  %-46s %s" % ("check", "state"))
    for label, new, old in checks:
        print("  %-46s %s" % (label, "APPLIED" if new else ("BASELINE" if old else "UNKNOWN")))
    return applied, len(checks)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--revert", action="store_true")
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    if args.revert:
        for n in (PLAT, UI, SPMI_REBOOT):
            restore(n)
        return

    print("=== star loader framebuffer truth ===")
    a, t = status()
    if args.check or not args.apply:
        print("  %d/%d applied" % (a, t))
        return

    if a == t:
        print("  already applied, nothing to do")
        return
    if a != 0:
        raise SystemExit("partially applied: use --revert first")

    for n in (PLAT, UI, SPMI_REBOOT):
        backup(n)

    p = read(PLAT)
    if OLD_PLATFORM not in p:
        raise SystemExit("platform_private.h: platform_star block not found verbatim")
    write(PLAT, p.replace(OLD_PLATFORM, NEW_PLATFORM))
    print("  platform_private.h: fb_base 0 -> 0xEA600000")

    u = read(UI)
    if OLD_FLUSH not in u:
        raise SystemExit("loader_06a_screen_ui.inc: ui_flush_splash_fb not found verbatim")
    u = u.replace(OLD_FLUSH, NEW_FLUSH)
    if u.count(OLD_BTN_GUARD) != 1:
        raise SystemExit("loader_06a_screen_ui.inc: SPMI button guard not unique")
    write(UI, u.replace(OLD_BTN_GUARD, NEW_BTN_GUARD))
    print("  loader_06a_screen_ui.inc: star dcache-only flush + PMIC guard comment")

    r = read(SPMI_REBOOT)
    if r.count(OLD_RB_GUARD) != 1:
        raise SystemExit("loader_spmi_reboot_private.h: guard not unique")
    write(SPMI_REBOOT, r.replace(OLD_RB_GUARD, NEW_RB_GUARD))
    print("  loader_spmi_reboot_private.h: PMIC guard comment")

    print("=== after ===")
    a, t = status()
    print("  %d/%d applied" % (a, t))
    if a != t:
        raise SystemExit("patch incomplete")
    print("DONE (loader source only; no image was built or flashed)")


if __name__ == "__main__":
    main()
