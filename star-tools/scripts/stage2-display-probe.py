#!/usr/bin/env python3
"""star-native stage 2: READ-ONLY survey of the SM8350 display pipeline.

Run after build-star-native-tree.py --reset and stage1-storage.py.
This writes code only; it does not flash anything and does not write a DPU
register.  The probe is gated behind the boot-arg star_display_probe=1 so the
first real flash can enable exactly one new variable.

All addresses come from star-B.dtb (parsed by parse-star-dtb.py) and from the
iOS16-era star loader (loader.c:907, splash framebuffer 0xEA600000).

Purpose of the survey: find out which DPU generation star actually has, what
the controller currently scans out, and whether the loader's boot UI is still
in the splash memory when the kernel starts.  The K90 tree guessed "DPU 12.0"
and a 0xFC800000 A/B splash; that guess is what wiped the boot console.
"""
import os

DST = "/root/star26/star-native"

PROBE_C = r'''/*
 * star_display_probe.c -- read-only survey of the Xiaomi 11 Ultra display
 * pipeline (star / SM8350).
 *
 * This file NEVER writes a device register.  It maps the MDSS blocks listed
 * in star-B.dtb and prints a handful of 32-bit values.  Offsets are kept as
 * raw numbers on purpose: the DPU generation of SM8350 is not yet confirmed
 * from the running machine, so naming them after another SoC's catalog would
 * repeat the mistake this tree was created to undo.  Once the values come
 * back, they are matched against the lahaina DPU catalog and only then does
 * the display driver get real register names.
 *
 * Avoided on purpose: interrupt-status and UIC error registers, which are
 * read-to-clear on Qualcomm display controllers.
 *
 * Addresses (star-B.dtb, parsed into C:/ios26/star-display-nodes.txt):
 *   qcom,mdss_mdp@ae00000        "qcom,sde-kms"      0xae00000 + 0x84000
 *   mdss_vbif@aeb0000                                0xaeb0000 + 0x2008
 *   mdss_dsi_ctrl0@ae94000       dsi-ctrl-hw-v2.5    0xae94000 + 0x400
 *   mdss_dsi_phy0@ae94900        dsi-phy-v4.2        phy 0xae94400 + 0x800
 *   cont_splash_memory           0xEA600000 (iOS16 loader.c:907)
 *   panel                        qcom,mdss_dsi_k3s_42_02_0b_dsc_cmd
 */
#include <sys/param.h>
#include <sys/systm.h>
#include <sys/types.h>
#include <mach/vm_param.h>
#include <pexpert/pexpert.h>

extern void IOLog(const char *format, ...);
extern vm_offset_t ml_io_map(vm_offset_t phys_addr, vm_size_t size);

#define STAR_MDP_PHYS       0x0AE00000ULL
#define STAR_MDP_SIZE       0x00084000ULL
#define STAR_VBIF_PHYS      0x0AEB0000ULL
#define STAR_VBIF_SIZE      0x00002008ULL
#define STAR_DSI0_PHYS      0x0AE94000ULL
#define STAR_DSI0_SIZE      0x00000400ULL
#define STAR_DSIPHY_PHYS    0x0AE94400ULL
#define STAR_DSIPHY_SIZE    0x00000800ULL
#define STAR_SPLASH_PHYS    0xEA600000ULL
/* ml_io_map() refuses very large mappings; one MiB is enough to sample the
 * first rows of the 1440x3200x4 splash framebuffer. */
#define STAR_SPLASH_WINDOW  0x00100000ULL

static uint32_t
star_rd(volatile uint8_t *base, vm_offset_t off)
{
	return *(volatile uint32_t *)(base + off);
}

void
star_display_probe(void)
{
	uint32_t ask = 0;
	volatile uint8_t *mdp, *vbif, *dsi, *phy, *splash;

	/* One variable at a time: the survey is off unless explicitly asked for. */
	if (!PE_parse_boot_argn("star_display_probe", &ask, sizeof(ask)) || ask == 0) {
		return;
	}

	mdp = (volatile uint8_t *)ml_io_map(STAR_MDP_PHYS, STAR_MDP_SIZE);
	vbif = (volatile uint8_t *)ml_io_map(STAR_VBIF_PHYS, STAR_VBIF_SIZE);
	dsi = (volatile uint8_t *)ml_io_map(STAR_DSI0_PHYS, STAR_DSI0_SIZE);
	phy = (volatile uint8_t *)ml_io_map(STAR_DSIPHY_PHYS, STAR_DSIPHY_SIZE);
	splash = (volatile uint8_t *)ml_io_map(STAR_SPLASH_PHYS, STAR_SPLASH_WINDOW);

	IOLog("star_display: READ-ONLY survey, star / SM8350, no register is written\n");
	IOLog("star_display: mappings mdp=%d vbif=%d dsi_ctrl0=%d dsi_phy0=%d splash=%d\n",
	    mdp != NULL, vbif != NULL, dsi != NULL, phy != NULL, splash != NULL);

	if (mdp != NULL) {
		IOLog("star_display: mdp head: %08x %08x %08x %08x %08x %08x %08x %08x\n",
		    star_rd(mdp, 0x00), star_rd(mdp, 0x04), star_rd(mdp, 0x08), star_rd(mdp, 0x0c),
		    star_rd(mdp, 0x10), star_rd(mdp, 0x14), star_rd(mdp, 0x18), star_rd(mdp, 0x1c));
		/* Candidate block bases.  The first word of each is usually a
		 * HW_VERSION / block id; that fingerprint decides the generation. */
		IOLog("star_display: mdp +0x1000: %08x %08x | +0x2000: %08x %08x | +0x3000: %08x %08x\n",
		    star_rd(mdp, 0x1000), star_rd(mdp, 0x1004),
		    star_rd(mdp, 0x2000), star_rd(mdp, 0x2004),
		    star_rd(mdp, 0x3000), star_rd(mdp, 0x3004));
		IOLog("star_display: mdp +0x4000: %08x %08x | +0x6000: %08x %08x | +0xa000: %08x %08x\n",
		    star_rd(mdp, 0x4000), star_rd(mdp, 0x4004),
		    star_rd(mdp, 0x6000), star_rd(mdp, 0x6004),
		    star_rd(mdp, 0xa000), star_rd(mdp, 0xa004));
	}
	if (vbif != NULL) {
		IOLog("star_display: vbif head: %08x %08x %08x %08x\n",
		    star_rd(vbif, 0x00), star_rd(vbif, 0x04), star_rd(vbif, 0x08), star_rd(vbif, 0x0c));
	}
	if (dsi != NULL) {
		IOLog("star_display: dsi_ctrl0 head (hw v2.5): %08x %08x %08x %08x\n",
		    star_rd(dsi, 0x00), star_rd(dsi, 0x04), star_rd(dsi, 0x08), star_rd(dsi, 0x0c));
	}
	if (phy != NULL) {
		IOLog("star_display: dsi_phy0 head (v4.2): %08x %08x %08x %08x\n",
		    star_rd(phy, 0x00), star_rd(phy, 0x04), star_rd(phy, 0x08), star_rd(phy, 0x0c));
	}
	if (splash != NULL) {
		/* Is the loader's boot UI still in cont_splash_region when the
		 * kernel starts?  Non-black pixels here prove it is. */
		IOLog("star_display: splash 0xEA600000 row0: %08x %08x %08x %08x\n",
		    star_rd(splash, 0x00), star_rd(splash, 0x04),
		    star_rd(splash, 0x08), star_rd(splash, 0x0c));
		IOLog("star_display: splash +0x1000: %08x | +0x10000: %08x | +0xf0000: %08x\n",
		    star_rd(splash, 0x1000), star_rd(splash, 0x10000), star_rd(splash, 0xf0000));
	}
	IOLog("star_display: survey done (still read-only)\n");
}
'''

DISPLAY_H = r'''#ifndef _SYS_STAR_DISPLAY_H_
#define _SYS_STAR_DISPLAY_H_

/* Read-only SM8350 display survey; enabled by boot-arg star_display_probe=1. */
void star_display_probe(void);

#endif /* _SYS_STAR_DISPLAY_H_ */
'''


def path(rel):
    return os.path.join(DST, rel)


def read(rel):
    with open(path(rel), errors="replace") as fh:
        return fh.read()


def write(rel, text):
    os.makedirs(os.path.dirname(path(rel)), exist_ok=True)
    with open(path(rel), "w") as fh:
        fh.write(text)


def replace(rel, old, new, count=1):
    text = read(rel)
    got = text.count(old)
    if got != count:
        raise SystemExit("EDIT FAILED %s: expected %d, got %d of %r" % (rel, count, got, old[:70]))
    write(rel, text.replace(old, new))
    print("  %-38s %d edit(s)" % (rel, got))


def main():
    print("=== stage 2: star read-only display survey ===")
    write("bsd/dev/star/star_display_probe.c", PROBE_C)
    print("  wrote bsd/dev/star/star_display_probe.c (%d bytes)" % len(PROBE_C))
    write("bsd/sys/star_display.h", DISPLAY_H)

    replace("bsd/conf/files",
            "bsd/dev/star/star_platform_stubs.c\tstandard\n",
            "bsd/dev/star/star_platform_stubs.c\tstandard\n"
            "bsd/dev/star/star_display_probe.c\tstandard\n")

    replace("bsd/kern/bsd_init.c",
            "#include <sys/annibale_input.h>\n",
            "#include <sys/annibale_input.h>\n"
            "#include <sys/star_display.h>\n")
    replace("bsd/kern/bsd_init.c",
            "\t\tannibale_ufs_init();\n"
            "\t\tannibale_input_init();           /* /dev/annibale-touch */\n",
            "\t\tannibale_ufs_init();\n"
            "\t\tstar_display_probe();             /* read-only, gated by star_display_probe=1 */\n"
            "\t\tannibale_input_init();           /* /dev/annibale-touch */\n")

    print("=== validation ===")
    # (file, token, minimum count); a count of 0 means "must be absent".
    checks = [
        ("bsd/dev/star/star_display_probe.c", "star_display_probe", 3),
        ("bsd/dev/star/star_display_probe.c", "0x0AE00000", 1),
        ("bsd/dev/star/star_display_probe.c", "0xEA600000", 1),
        ("bsd/dev/star/star_display_probe.c", "0x0AE94000", 1),
        ("bsd/dev/star/star_display_probe.c", "0xFC800000", 0),
        ("bsd/dev/star/star_display_probe.c", "DPU 12.0", 0),
        ("bsd/dev/star/star_display_probe.c", "IOLog(", 10),
        ("bsd/conf/files", "star_display_probe.c", 1),
        ("bsd/kern/bsd_init.c", "star_display_probe();", 1),
        ("bsd/kern/bsd_init.c", "#include <sys/star_display.h>", 1),
    ]
    bad = 0
    for rel, token, want in checks:
        got = read(rel).count(token)
        ok = (got == 0) if want == 0 else (got >= want)
        mark = "OK" if ok else "FAIL"
        if not ok:
            bad += 1
        print("  %-4s %-42s %-28s %d (want %s%d)" %
              (mark, rel, token, got, "0" if want == 0 else ">=", want))
    if bad:
        raise SystemExit("stage 2 validation failed: %d mismatch(es)" % bad)
    print("DONE")


if __name__ == "__main__":
    main()
