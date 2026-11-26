/*
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
