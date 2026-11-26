/*
 * The touch screen of the POCO X5 Pro (redwood): either a Goodix GT9916 ("Berlin-D") or a
 * FocalTech FT3680 on the SPI bus of the SoC's serial engine 13, as a source of touches for
 * /dev/redwood-touch (sys/redwood_input.h). Only with boot-arg touchscreen=1: every address
 * below belongs to this phone.
 *
 * There is no clock, pin, regulator or SPI framework in this kernel, so the driver does all of
 * it itself, in the order the vendor's Linux drivers do:
 *   power    the chip's I/O supply is LDO2 of the PM8350C, switched through RPMh (one request
 *            written into the "always on" processor's command slots); the analog supply is
 *            behind a GPIO
 *   clocks   the serial engine's three clocks, by vote in the global clock controller
 *   pins     four GPIOs to the serial engine, plus reset, interrupt and the analog supply switch
 *   SPI      the serial engine ("GENI") in FIFO mode, polled; or, if the engine cannot be used,
 *            the same four pins driven by hand
 *   panel    GPIO96=1 and GPIO68=0 identify the FocalTech variant; everything else is Goodix,
 *            the same discriminator the vendor sm8350-kernel-OKX uses
 *   chip     Goodix: find where it keeps the touch report, then read it when the IRQ line signals;
 *            FocalTech: read the report at register 0x01 with FTS 5.x SPI framing (cmd 0xC1 for
 *            read, 0xC0 for write, two-byte CRC-16/Kermit)
 * No interrupt is used: a thread looks at the interrupt line 125 times a second (boot-arg
 * touch_poll_us=N: every N microseconds instead of 8000). With touch_lat=1 a line for every report
 * read ("tl: c before US seen US read US": the look before, the look that found the line low, the
 * report read), for measuring how long a touch takes to show (tools/latency.py).
 *
 * Register layouts: Linux drivers/spi/spi-geni-qcom.c, drivers/soc/qcom/{qcom-geni-se,rpmh-rsc,
 * cmd-db}.c, drivers/clk/qcom/gcc-sc7280.c, drivers/pinctrl/qcom/pinctrl-sc7280.c,
 * drivers/input/touchscreen/{goodix_berlin_*,focaltech_touch/focaltech_core}.c, and the phone's
 * own device tree.
 */
#include <kern/clock.h>
#include <kern/thread.h>
#include <libkern/libkern.h>
#include <mach/mach_types.h>
#include <pexpert/pexpert.h>
#include <sys/annibale_input.h>
#include <sys/systm.h>

extern void annibale_tl(const char *format, ...) __printflike(1, 2);
extern void loader_log_line(const char *line);

extern vm_offset_t ml_io_map(vm_offset_t phys_addr, vm_size_t size);
extern vm_offset_t ml_io_map_wcomb(vm_offset_t phys_addr, vm_size_t size);
extern kern_return_t thread_terminate(thread_t thread);

static vm_offset_t tlmm, gcc, se, rsc, cmd_db;

/*
 * The driver's own lines go straight into the loader's log instead of through printf: at the point
 * where this driver starts (inside the BSD init, before the console is of any use) printf's output
 * never reaches the log, while loader_log_line() -- the same path the latency lines take -- does.
 */
extern void loader_log_putc(char c);

static void
goodix_trace(const char *format, ...) __printflike(1, 2);

static void
goodix_trace(const char *format, ...)
{
	char line[512];
	va_list list;
	int n;

	va_start(list, format);
	n = vsnprintf(line, sizeof(line), format, list);
	va_end(list);
	if (n < 0) return;
	if (n > (int)sizeof(line) - 1) n = (int)sizeof(line) - 1;
	for (int i = 0; i < n; i++) loader_log_putc(line[i]);
}

static inline uint32_t
rd(vm_offset_t address)
{
	return *(volatile uint32_t *)address;
}

static inline void
wr(vm_offset_t address, uint32_t value)
{
	*(volatile uint32_t *)address = value;
}

static void
sleep_us(uint32_t us)
{
	delay_for_interval(us, NSEC_PER_USEC);
}

static void
sleep_ms(uint32_t ms)
{
	delay_for_interval(ms, NSEC_PER_MSEC);
}

/* ---- pins (TLMM) ------------------------------------------------------------------------------- */

/*
 * The pin controller's registers. POCO X5 Pro (SC7280/redwood) has them at 0x0f100000; the Xiaomi 11
 * Ultra (SM8350/star) at 0x0f000000. Both keep one 0x1000-byte block per pin, but the star starts its
 * pins at the *second* block: block 0 is the controller's own registers, and writing to it takes the
 * whole system down (which is how this was found -- see gpio_block). Boot-arg touch_tlmm=<hex>
 * overrides the base.
 */
#define TLMM_PHYS_REDWOOD       0x0f100000UL
/*
 * The vendor device tree calls the controller "pinctrl@f000000" with a 16 MiB reg, but that is the
 * start of a wrapper: the pin array itself is at +0x100000, exactly where mainline sm8350.dtsi puts
 * tlmm (pinctrl@f100000) and where the oneplus-9/SM8350 reference driver reads its pins. Reads at
 * 0x0f000000 come back as zeros and writes are silently dropped -- which is why no pin ever changed.
 */
#define TLMM_PHYS_STAR          0x0f100000UL
#define TLMM_SIZE               0x100000UL
#define GPIO_CFG(n)             (tlmm + 0x1000UL * ((n) + gpio_block))   /* [1:0] pull, [5:2] function, [8:6] drive, [9] output */
#define GPIO_IO(n)              (tlmm + 0x1000UL * ((n) + gpio_block) + 4) /* bit 0 in, bit 1 out */
#define PULL_NONE               0
#define PULL_UP                 3

/* First block that holds gpio0. The pin controller of both phones keeps one 0x1000-byte block per pin
 * starting at gpio0, so this is 0; diagnose() checks it against the hardware and can change it. */
static unsigned gpio_block = 0;

#define PIN_MISO                48
#define PIN_MOSI                49
#define PIN_CLK                 50
#define PIN_CS                  51
#define PIN_INT                 23      /* low = the chip has a report */
#define PIN_RESET               22     /* low = in reset */
#define PIN_AVDD_REDWOOD        12      /* redwood: high = analog supply on ... */
#define PIN_AVDD_STAR           132     /* ... star: touch_avddsource_vreg (gpio132, active high) */
#define PIN_VDD_STAR            154     /* star: touch_vdd_vreg (gpio154, active high); redwood has none */
#define PIN_FOCALTECH_ID        68      /* FocalTech if this reads 0 ... */
#define PIN_GOODIX_ID           96      /* ... and this reads 1 (sm8350-kernel-OKX convention) */
/*
 * The number the pin controller wants for its "qup11" function (gpio48..51 on the star). The device
 * tree names the function, the register takes its place in the controller's own list -- "gpio" is 0
 * and the rest follow in alphabetical order, so "qup11" is not the first alternate function, which is
 * what this driver used to write. Writing the wrong number leaves the pins in ATEST and the serial
 * engine talking to nothing. diagnose() asks the hardware which number works; touch_spi_func=N wins.
 */
#define PIN_FUNCTION_SPI        1
static unsigned spi_function = PIN_FUNCTION_SPI;
static bool spi_function_given;         /* touch_spi_func=N was on the command line: do not sweep */

static void
gpio_configure(unsigned pin, unsigned function, unsigned pull, unsigned ma, bool output)
{
	wr(GPIO_CFG(pin), pull | function << 2 | (ma / 2 - 1) << 6 | (output ? 1u << 9 : 0));
}

static void
gpio_set(unsigned pin, bool high)
{
	wr(GPIO_IO(pin), high ? 2 : 0);
}

static bool
gpio_get(unsigned pin)
{
	return rd(GPIO_IO(pin)) & 1;
}

static void
gpio_output(unsigned pin, bool high, unsigned pull, unsigned ma)
{
	gpio_set(pin, high);            /* the level first, so that the pin never drives the wrong one */
	gpio_configure(pin, 0, pull, ma, true);
}

/* ---- the I/O supply (RPMh) ----------------------------------------------------------------------- */

#define CMD_DB_PHYS             0x80860000UL
#define CMD_DB_SIZE             0x20000UL
#define RSC_PHYS                0x18220000UL    /* the application processor's "DRV 2" */
#define RSC_SIZE                0x10000UL
#define TCS(reg)                (rsc + 0xd00 + (reg))           /* command slot set 0, an "active" one */
#define TCS_IRQ_ENABLE          0x00
#define TCS_IRQ_STATUS          0x04
#define TCS_IRQ_CLEAR           0x08
#define TCS_WAIT_FOR_COMPLETION 0x10
#define TCS_CONTROL             0x14
#define TCS_CONTROL_ENABLE      (1u << 16)
#define TCS_CONTROL_TRIGGER     (1u << 24)
#define TCS_STATUS              0x18            /* 0 while busy */
#define TCS_CMD_ENABLE          0x1c
#define TCS_CMD_MSGID(n)        (0x30 + 20 * (n))
#define TCS_CMD_ADDR(n)         (0x34 + 20 * (n))
#define TCS_CMD_DATA(n)         (0x38 + 20 * (n))
#define MSGID_WRITE_4_BYTES     0x10008
#define MSGID_RESPONSE          0x100

#define VRM_VOLTAGE             0               /* a regulator's registers, from its address: millivolts */
#define VRM_ENABLE              4
#define VRM_MODE                8
#define VRM_MODE_LDO_HPM        7

struct cmd_db_slave {
	uint16_t id, header_offset, data_offset, count, version, reserved[3];
};
struct cmd_db_header {
	uint32_t version;
	uint8_t magic[4];
	struct cmd_db_slave slave[8];
	uint32_t checksum, reserved;
	uint8_t data[];
};
struct cmd_db_entry {
	char id[8];
	uint32_t priority[2];
	uint32_t address;
	uint16_t length, offset;
};

/* The RPMh address of a resource by its name in the command database the boot loader left; 0 = none. */
static uint32_t
rpmh_address(const char *name)
{
	const struct cmd_db_header *db = (const struct cmd_db_header *)cmd_db;
	char id[8] = { 0 };

	if (db->magic[0] != 0xdb || db->magic[1] != 0x30 || db->magic[2] != 0x03 || db->magic[3] != 0x0c) {
		goodix_trace("goodix: no command database (magic %02x %02x %02x %02x)\n", db->magic[0], db->magic[1], db->magic[2],
		    db->magic[3]);
		return 0;
	}
	strlcpy(id, name, sizeof(id));
	for (unsigned s = 0; s < 8; s++) {
		const struct cmd_db_slave *slave = &db->slave[s];
		const struct cmd_db_entry *entry = (const struct cmd_db_entry *)(db->data + slave->header_offset);

		if (slave->id == 0 || slave->header_offset >= CMD_DB_SIZE - 0x1000 || slave->count > 512) {
			continue;
		}
		for (unsigned i = 0; i < slave->count; i++) {
			if (memcmp(entry[i].id, id, sizeof(id)) == 0) {
				return entry[i].address;
			}
		}
	}
	return 0;
}

static bool
rpmh_wait(uint32_t reg, uint32_t mask, uint32_t value, const char *what)
{
	for (int i = 0; i < 2000; i++) {
		if ((rd(TCS(reg)) & mask) == value) {
			return true;
		}
		sleep_us(100);
	}
	goodix_trace("goodix: RPMh: timeout waiting for %s (register %#x = %#x)\n", what, reg, rd(TCS(reg)));
	return false;
}

/* Send up to three register writes to RPMh and wait until they are done. */
static bool
rpmh_write(const uint32_t *address, const uint32_t *data, unsigned count)
{
	uint32_t irq_enable = rd(TCS(TCS_IRQ_ENABLE));
	bool done;

	/* the slot set must be idle, and switched off the way the hardware wants it: trigger, then enable */
	for (int i = 0; rd(TCS(TCS_STATUS)) == 0; i++) {
		if (i > 2000) {
			goodix_trace("goodix: RPMh: the command slots stay busy\n");
			return false;
		}
		sleep_us(100);
	}
	wr(TCS(TCS_CONTROL), rd(TCS(TCS_CONTROL)) & ~TCS_CONTROL_TRIGGER);
	wr(TCS(TCS_CONTROL), rd(TCS(TCS_CONTROL)) & ~TCS_CONTROL_ENABLE);
	wr(TCS(TCS_IRQ_CLEAR), 1);
	for (unsigned i = 0; i < count; i++) {
		wr(TCS(TCS_CMD_MSGID(i)), MSGID_WRITE_4_BYTES | MSGID_RESPONSE);
		wr(TCS(TCS_CMD_ADDR(i)), address[i]);
		wr(TCS(TCS_CMD_DATA(i)), data[i]);
	}
	wr(TCS(TCS_WAIT_FOR_COMPLETION), (1u << count) - 1);
	wr(TCS(TCS_CMD_ENABLE), (1u << count) - 1);
	wr(TCS(TCS_IRQ_ENABLE), irq_enable | 1);        /* the status bit follows the enable; the interrupt itself stays masked */
	wr(TCS(TCS_CONTROL), TCS_CONTROL_ENABLE);
	wr(TCS(TCS_CONTROL), TCS_CONTROL_ENABLE | TCS_CONTROL_TRIGGER);

	done = rpmh_wait(TCS_IRQ_STATUS, 1, 1, "the request");
	wr(TCS(TCS_CONTROL), rd(TCS(TCS_CONTROL)) & ~TCS_CONTROL_TRIGGER);
	wr(TCS(TCS_CONTROL), rd(TCS(TCS_CONTROL)) & ~TCS_CONTROL_ENABLE);
	wr(TCS(TCS_CMD_ENABLE), 0);
	wr(TCS(TCS_WAIT_FOR_COMPLETION), 0);
	wr(TCS(TCS_IRQ_CLEAR), 1);
	wr(TCS(TCS_IRQ_ENABLE), irq_enable);
	return done;
}

/* The chip's I/O supply: 1.8 V from LDO2 of the PM8350C ("ldoc2"). Nothing else is connected to it. */
static bool
io_supply_on(void)
{
	uint32_t base = rpmh_address("ldoc2");
	uint32_t address[3] = { base + VRM_VOLTAGE, base + VRM_ENABLE, base + VRM_MODE };
	uint32_t data[3] = { 1800, 1, VRM_MODE_LDO_HPM };

	/* addresses of regulators ("VRM") have 4 in bits 19:16; anything else is not what we are looking for */
	if (base == 0 || (base >> 16 & 0xf) != 4) {
		goodix_trace("goodix: RPMh: no regulator \"ldoc2\" (address %#x)\n", base);
		return false;
	}
	goodix_trace("goodix: RPMh: ldoc2 is at %#x; slot status %#x, control %#x, irq enable %#x status %#x\n", base,
	    rd(TCS(TCS_STATUS)), rd(TCS(TCS_CONTROL)), rd(TCS(TCS_IRQ_ENABLE)), rd(TCS(TCS_IRQ_STATUS)));
	if (!rpmh_write(address, data, 3)) {
		return false;
	}
	goodix_trace("goodix: I/O supply on (1.8 V)\n");
	return true;
}

/* ---- clocks (GCC) -------------------------------------------------------------------------------- */

#define GCC_PHYS                0x00100000UL
#define GCC_SIZE                0x60000UL
#define GCC_VOTE                (gcc + 0x52008)         /* the application processor's votes */
#define VOTE_QUP1_CORE_2X       (1u << 18)
#define VOTE_QUP1_CORE          (1u << 19)
#define VOTE_QUP1_M_AHB         (1u << 20)
#define VOTE_QUP1_S_AHB         (1u << 21)
#define GCC_QUP1_M_AHB_CBCR     (gcc + 0x18004)         /* bit 31: the clock is off */
#define GCC_QUP1_S_AHB_CBCR     (gcc + 0x18008)
#define CLOCK_OFF               (1u << 31)
#define XO_HZ                   19200000

/*
 * Where the touch screen's serial engine sits, and the three numbers that go with it in the global
 * clock controller: its branch (whose bit 31 tells whether the clock runs), the command register of
 * its root clock generator (the divider and source live in the four bytes after it), and the bit that
 * votes for it in GCC_VOTE. All of wrap 1's serial engines share one vote register and one pair of
 * AHB branches; only these three numbers differ from engine to engine.
 *
 *   star      -- Xiaomi 11 Ultra (SM8350): the serial engine at 0xa8c000, the fourth of wrap 1
 *                (gcc_qupv3_wrap1_s3_clk: halt 0x1839c, vote bit 25)
 *   redwood   -- POCO X5 Pro (SC7280): the engine at 0xa94000, the sixth of wrap 1
 *                (gcc_qupv3_wrap1_s5_clk: halt 0x185fc, vote bit 27)
 */
struct se_site {
	uint32_t phys, cbcr, cmd, vote;
	const char *name;
};

static const struct se_site se_sites[] = {
	{ 0x00a8c000, 0x1839c, 0x183a0, 25, "star" },
	{ 0x00a94000, 0x185fc, 0x18600, 27, "redwood" },
};

static const struct se_site *site = &se_sites[0];       /* star unless the engine says otherwise */
static uint32_t se_cmd_off, se_cbcr_off, se_vote_bit;

#define GCC_SE_CBCR             (gcc + se_cbcr_off)
#define GCC_SE_CMD              (gcc + se_cmd_off)
#define GCC_SE_CFG              (gcc + se_cmd_off + 4)
#define GCC_SE_DFSR             (gcc + se_cmd_off + 0x14)
#define GCC_SE_PERF_CFG(l)      (gcc + se_cmd_off + 0x1c + 4 * (l))
#define GCC_SE_PERF_M(l)        (gcc + se_cmd_off + 0x5c + 4 * (l))
#define GCC_SE_PERF_N(l)        (gcc + se_cmd_off + 0x9c + 4 * (l))

static uint32_t se_source_hz, se_clock_select;

static uint32_t
rcg_rate(uint32_t cfg, uint32_t m, uint32_t not_n_minus_m)
{
	static const uint32_t parent[8] = { XO_HZ, 600000000, 0, 0, 0, 0, 300000000, 0 };
	uint64_t hz = parent[cfg >> 8 & 7];
	uint32_t divider = cfg & 0x1f, mode = cfg >> 12 & 3;

	if (divider) {
		hz = hz * 2 / (divider + 1);
	}
	if (mode) {
		uint32_t n = (~not_n_minus_m & 0xffff) + (m & 0xffff);

		if (n) {
			hz = hz * (m & 0xffff) / n;
		}
	}
	return (uint32_t)hz;
}

static bool
clocks_on(void)
{
	wr(GCC_VOTE, rd(GCC_VOTE) | VOTE_QUP1_CORE_2X | VOTE_QUP1_CORE | VOTE_QUP1_M_AHB | VOTE_QUP1_S_AHB);
	goodix_trace("goodix: the serial engine at %#x (the %s one): clock branch %#x, command %#x, vote bit %u\n",
	    site->phys, site->name, se_cbcr_off, se_cmd_off, se_vote_bit);
	if (rd(GCC_SE_DFSR) & 1) {
		/* preset rates: the lowest that is at least 4 MHz */
		for (uint32_t level = 0; level < 8; level++) {
			uint32_t hz = rcg_rate(rd(GCC_SE_PERF_CFG(level)), rd(GCC_SE_PERF_M(level)),
			    rd(GCC_SE_PERF_N(level)));

			if (hz >= 4000000 && (se_source_hz == 0 || hz < se_source_hz)) {
				se_source_hz = hz;
				se_clock_select = level;
			}
		}
		if (se_source_hz == 0) {
			goodix_trace("goodix: no usable preset clock rate\n");
			return false;
		}
	} else {
		/* the crystal, undivided: nothing else has to be running */
		wr(GCC_SE_CFG, (rd(GCC_SE_CFG) & ~0x371fu) | 1);
		wr(GCC_SE_CMD, rd(GCC_SE_CMD) | 1);
		for (int i = 0; i < 500 && (rd(GCC_SE_CMD) & 1); i++) {
			sleep_us(10);
		}
		if (rd(GCC_SE_CMD) & 1) {
			goodix_trace("goodix: the serial engine's clock does not take its configuration (%#x)\n", rd(GCC_SE_CMD));
			return false;
		}
		se_source_hz = XO_HZ;
		se_clock_select = 0;
	}
	wr(GCC_VOTE, rd(GCC_VOTE) | (1u << se_vote_bit));

	/*
	 * The serial engine's own branch is what has to run: its halt bit clears as soon as the engine's
	 * clock is on. The two AHB branches are voted by the same write, but their halt bit is a "voted"
	 * one that the hardware reports as still set on both phones even while the bus runs (POCO X5 Pro's
	 * log says 0x80000002 for it as well), so a set bit there is told, not obeyed.
	 */
	for (int i = 0; i < 1000; i++) {
		if (!(rd(GCC_SE_CBCR) & CLOCK_OFF)) {
			goodix_trace("goodix: the serial engine's clock runs (branch %#x, ahb %#x/%#x); the source %u Hz\n",
			    rd(GCC_SE_CBCR), rd(GCC_QUP1_M_AHB_CBCR), rd(GCC_QUP1_S_AHB_CBCR), se_source_hz);
			return true;
		}
		sleep_us(10);
	}
	goodix_trace("goodix: the engine's clock stays off: %#x (ahb %#x %#x)\n", rd(GCC_SE_CBCR),
	    rd(GCC_QUP1_M_AHB_CBCR), rd(GCC_QUP1_S_AHB_CBCR));
	return false;
}

/* ---- SPI through the serial engine (GENI) ---------------------------------------------------------- */

#define SE_SIZE                 0x4000UL
#define GENI_FORCE_DEFAULT      (se + 0x020)
#define GENI_OUTPUT_CTRL        (se + 0x024)
#define GENI_CGC_CTRL           (se + 0x028)
#define GENI_STATUS             (se + 0x040)    /* bit 0: a command is running */
#define GENI_SER_M_CLK_CFG      (se + 0x048)    /* bit 0 enable, [15:4] divider */
#define GENI_IF_DISABLE_RO      (se + 0x064)    /* bit 0: no FIFO interface */
#define GENI_FW_REVISION_RO     (se + 0x068)    /* [15:8] protocol: 1 = SPI */
#define GENI_CLK_SEL            (se + 0x07c)
#define SPI_CPHA                (se + 0x224)
#define SPI_LOOPBACK            (se + 0x22c)
#define SPI_CPOL                (se + 0x230)
#define SPI_DEMUX_OUTPUT_INV    (se + 0x24c)
#define SPI_DEMUX_SEL           (se + 0x250)
#define GENI_BYTE_GRAN          (se + 0x254)
#define GENI_DMA_MODE_EN        (se + 0x258)
#define SPI_TRANS_CFG           (se + 0x25c)
#define GENI_TX_PACKING_CFG0    (se + 0x260)
#define GENI_TX_PACKING_CFG1    (se + 0x264)
#define SPI_WORD_LEN            (se + 0x268)
#define SPI_TX_TRANS_LEN        (se + 0x26c)
#define SPI_RX_TRANS_LEN        (se + 0x270)
#define SPI_DELAY_COUNTERS      (se + 0x278)
#define GENI_RX_PACKING_CFG0    (se + 0x284)
#define GENI_RX_PACKING_CFG1    (se + 0x288)
#define GENI_M_CMD0             (se + 0x600)    /* [31:27] operation */
#define GENI_M_CMD_CTRL         (se + 0x604)    /* bit 2 cancel, bit 1 abort */
#define GENI_M_IRQ_STATUS       (se + 0x610)
#define GENI_M_IRQ_EN           (se + 0x614)
#define GENI_M_IRQ_CLEAR        (se + 0x618)
#define GENI_S_IRQ_CLEAR        (se + 0x648)
#define GENI_TX_FIFO            (se + 0x700)
#define GENI_RX_FIFO            (se + 0x780)
#define GENI_TX_FIFO_STATUS     (se + 0x800)    /* [27:0] words */
#define GENI_RX_FIFO_STATUS     (se + 0x804)    /* bit 31 last, [30:28] bytes of the last word, [24:0] words */
#define GENI_TX_WATERMARK       (se + 0x80c)
#define GENI_RX_WATERMARK       (se + 0x810)
#define GENI_RX_RFR_WATERMARK   (se + 0x814)
#define SE_DMA_TX_IRQ_CLR       (se + 0xc44)
#define SE_DMA_RX_IRQ_CLR       (se + 0xd44)
#define SE_GSI_EVENT_EN         (se + 0xe18)
#define SE_IRQ_EN               (se + 0xe1c)
#define SE_HW_PARAM_0           (se + 0xe24)    /* [21:16] FIFO depth in words */
#define SE_DMA_GENERAL_CFG      (se + 0xe30)

#define M_CMD_DONE              (1u << 0)
#define M_CMD_CANCEL            (1u << 4)
#define M_CMD_ABORT             (1u << 5)
#define M_ERRORS                ((1u << 1) | (1u << 2) | (1u << 3) | (1u << 24) | (1u << 25) | (1u << 28) | (1u << 29))
#define SPI_FULL_DUPLEX         (3u << 27)

static uint32_t fifo_depth;

/* 0 = ready; otherwise why the engine cannot be used */
static const char *
geni_spi_init(uint32_t hz)
{
	uint32_t divider;

	if ((rd(GENI_FW_REVISION_RO) >> 8 & 0xff) != 1) {
		return "the serial engine has no SPI firmware";
	}
	if (rd(GENI_IF_DISABLE_RO) & 1) {
		return "the serial engine's FIFO interface is disabled";
	}
	fifo_depth = rd(SE_HW_PARAM_0) >> 16 & 0x3f;
	if (fifo_depth < 4) {
		return "the serial engine reports no FIFO";
	}
	wr(SE_GSI_EVENT_EN, 0);
	wr(GENI_M_IRQ_CLEAR, 0xffffffff);
	wr(GENI_S_IRQ_CLEAR, 0xffffffff);
	wr(SE_DMA_TX_IRQ_CLR, 0xffffffff);
	wr(SE_DMA_RX_IRQ_CLR, 0xffffffff);
	wr(GENI_CGC_CTRL, rd(GENI_CGC_CTRL) | 0x7f);
	wr(SE_DMA_GENERAL_CFG, rd(SE_DMA_GENERAL_CFG) | 0xf);
	wr(GENI_OUTPUT_CTRL, 0x7f);
	wr(GENI_FORCE_DEFAULT, 1);
	wr(GENI_DMA_MODE_EN, rd(GENI_DMA_MODE_EN) & ~1u);
	wr(GENI_RX_WATERMARK, fifo_depth - 3);
	wr(GENI_RX_RFR_WATERMARK, fifo_depth - 2);
	wr(GENI_TX_WATERMARK, 0);
	/* the status bits we poll follow these enables; the interrupt itself stays masked at the GIC */
	wr(SE_IRQ_EN, rd(SE_IRQ_EN) | 0xf);
	wr(GENI_M_IRQ_EN, rd(GENI_M_IRQ_EN) | 0x7fc0007f);

	/* mode 0, chip select 0, 8 bits, most significant first, four bytes in a FIFO word */
	wr(SPI_LOOPBACK, 0);
	wr(SPI_DEMUX_SEL, 0);
	wr(SPI_CPHA, 0);
	wr(SPI_CPOL, 0);
	wr(SPI_DEMUX_OUTPUT_INV, 0);
	wr(SPI_TRANS_CFG, rd(SPI_TRANS_CFG) & ~2u);
	wr(SPI_DELAY_COUNTERS, 0);
	wr(GENI_TX_PACKING_CFG0, 0x0007f8fe);
	wr(GENI_TX_PACKING_CFG1, 0x000ffefe);
	wr(GENI_RX_PACKING_CFG0, 0x0007f8fe);
	wr(GENI_RX_PACKING_CFG1, 0x000ffefe);
	wr(GENI_BYTE_GRAN, 0);
	wr(SPI_WORD_LEN, 8 - 4);

	divider = (se_source_hz + hz - 1) / hz;
	wr(GENI_CLK_SEL, se_clock_select & 7);
	wr(GENI_SER_M_CLK_CFG, (divider ? divider : 1) << 4 | 1);
	return NULL;
}

static void
geni_drain(uint8_t *rx, uint32_t length, uint32_t *received)
{
	uint32_t status = rd(GENI_RX_FIFO_STATUS), words = status & 0x01ffffff, bytes = words * 4;

	if (status & 0x80000000u) {
		uint32_t valid = status >> 28 & 7;

		if (valid && valid < 4) {
			bytes -= 4 - valid;
		}
	}
	for (uint32_t i = 0; i < words; i++) {
		uint32_t word = rd(GENI_RX_FIFO);

		for (int j = 0; j < 4 && bytes; j++, bytes--) {
			if (*received < length) {
				if (rx) {
					rx[*received] = (uint8_t)(word >> (8 * j));
				}
				(*received)++;
			}
		}
	}
}

static void
geni_recover(void)
{
	wr(GENI_M_CMD_CTRL, 1u << 2);
	for (int i = 0; i < 2000 && !(rd(GENI_M_IRQ_STATUS) & M_CMD_CANCEL); i++) {
		sleep_us(100);
	}
	if (!(rd(GENI_M_IRQ_STATUS) & M_CMD_CANCEL)) {
		wr(GENI_M_CMD_CTRL, 1u << 1);
		for (int i = 0; i < 2000 && !(rd(GENI_M_IRQ_STATUS) & M_CMD_ABORT); i++) {
			sleep_us(100);
		}
	}
	for (int i = 0; i < 64 && (rd(GENI_RX_FIFO_STATUS) & 0x01ffffff); i++) {
		(void)rd(GENI_RX_FIFO);
	}
	wr(GENI_M_IRQ_CLEAR, 0xffffffff);
}

/* One transfer with the chip selected throughout: `length` bytes out (zeros without tx) and as many in. */
static bool
geni_transfer(const uint8_t *tx, uint8_t *rx, uint32_t length)
{
	static unsigned complaints;
	uint32_t sent = 0, received = 0, status = 0;
	uint64_t deadline;

	for (int i = 0; rd(GENI_STATUS) & 1; i++) {
		if (i > 2000) {
			geni_recover();
			break;
		}
		sleep_us(100);
	}
	wr(GENI_M_IRQ_CLEAR, 0xffffffff);
	wr(SPI_TX_TRANS_LEN, length);
	wr(SPI_RX_TRANS_LEN, length);
	wr(GENI_M_CMD0, SPI_FULL_DUPLEX);
	clock_interval_to_deadline(200, NSEC_PER_MSEC, &deadline);
	while (mach_absolute_time() < deadline) {
		while (sent < length && (rd(GENI_TX_FIFO_STATUS) & 0x0fffffff) + 1 < fifo_depth) {
			uint32_t word = 0;

			for (int j = 0; j < 4 && sent < length; j++, sent++) {
				word |= (uint32_t)(tx ? tx[sent] : 0) << (8 * j);
			}
			wr(GENI_TX_FIFO, word);
		}
		status = rd(GENI_M_IRQ_STATUS);
		geni_drain(rx, length, &received);
		if (status & M_ERRORS) {
			break;
		}
		if (status & M_CMD_DONE) {
			geni_drain(rx, length, &received);
			wr(GENI_M_IRQ_CLEAR, status);
			if (received == length) {
				return true;
			}
			break;
		}
	}
	if (complaints++ < 8) {
		goodix_trace("goodix: SPI transfer of %u bytes failed: status %#x, sent %u, received %u\n", length, status, sent,
		    received);
	}
	geni_recover();
	return false;
}

/* ---- SPI by hand, on the same pins ----------------------------------------------------------------- */

static unsigned bitbang_in = PIN_MISO, bitbang_out = PIN_MOSI;

static void
bitbang_init(void)
{
	gpio_output(PIN_CS, true, PULL_NONE, 6);
	gpio_output(PIN_CLK, false, PULL_NONE, 6);
	gpio_output(bitbang_out, false, PULL_NONE, 6);
	gpio_configure(bitbang_in, 0, PULL_NONE, 2, false);
}

static bool
bitbang_transfer(const uint8_t *tx, uint8_t *rx, uint32_t length)
{
	gpio_set(PIN_CS, false);
	for (uint32_t i = 0; i < length; i++) {
		uint8_t out = tx ? tx[i] : 0, in = 0;

		for (int bit = 7; bit >= 0; bit--) {
			gpio_set(bitbang_out, out >> bit & 1);
			gpio_set(PIN_CLK, true);
			in = (uint8_t)(in << 1 | gpio_get(bitbang_in));
			gpio_set(PIN_CLK, false);
		}
		if (rx) {
			rx[i] = in;
		}
	}
	gpio_set(PIN_CS, true);
	return true;
}

static bool (*spi_transfer)(const uint8_t *tx, uint8_t *rx, uint32_t length);

/* ---- the Goodix chip ------------------------------------------------------------------------------- */

#define GOODIX_FW_VERSION       0x10014         /* 28 bytes */
#define GOODIX_IC_INFO          0x10070         /* a 16-bit length, then that many bytes */
#define GOODIX_MAX_READ         1024
#define GOODIX_MAX_TOUCHES      10
#define GOODIX_STATUS_TOUCH     0x80
#define GOODIX_STATUS_REQUEST   0x40
#define GOODIX_REQUEST_RESET    3

static uint8_t spi_tx[8 + GOODIX_MAX_READ], spi_rx[8 + GOODIX_MAX_READ];
static uint32_t touch_address, command_address;
static const char *report_rate = "240";        /* what the status line says (touch_rate=480) */
static uint32_t max_x = 10800, max_y = 24000;   /* the device tree's; the chip may say otherwise */

static bool
goodix_read(uint32_t address, uint8_t *data, uint32_t length)
{
	if (length > GOODIX_MAX_READ) {
		return false;
	}
	spi_tx[0] = 0xf1;
	spi_tx[1] = (uint8_t)(address >> 24);
	spi_tx[2] = (uint8_t)(address >> 16);
	spi_tx[3] = (uint8_t)(address >> 8);
	spi_tx[4] = (uint8_t)address;
	spi_tx[5] = spi_tx[6] = spi_tx[7] = 0xff;
	memset(spi_tx + 8, 0, length);
	if (!spi_transfer(spi_tx, spi_rx, 8 + length)) {
		return false;
	}
	memcpy(data, spi_rx + 8, length);
	return true;
}

static bool
goodix_write(uint32_t address, const uint8_t *data, uint32_t length)
{
	if (length > GOODIX_MAX_READ) {
		return false;
	}
	spi_tx[0] = 0xf0;
	spi_tx[1] = (uint8_t)(address >> 24);
	spi_tx[2] = (uint8_t)(address >> 16);
	spi_tx[3] = (uint8_t)(address >> 8);
	spi_tx[4] = (uint8_t)address;
	memcpy(spi_tx + 5, data, length);
	return spi_transfer(spi_tx, NULL, 5 + length);
}

/* The chip's blocks end in the 16-bit sum of their bytes; all zeros or all ones is no answer at all. */
static bool
goodix_checksum_ok(const uint8_t *data, uint32_t length)
{
	uint32_t sum = 0;
	bool blank = true;

	if (length < 2) {
		return false;
	}
	for (uint32_t i = 0; i < length - 2; i++) {
		sum += data[i];
		blank &= data[i] == 0 || data[i] == 0xff;
	}
	return !blank && (uint16_t)sum == (uint16_t)(data[length - 2] | data[length - 1] << 8);
}

static uint16_t
le16(const uint8_t *p)
{
	return (uint16_t)(p[0] | p[1] << 8);
}

static uint32_t
le32(const uint8_t *p)
{
	return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24;
}

/*
 * Reset, held low for a whole second: the vendor driver of the Xiaomi 11 Ultra's FTS K2
 * (fts_chip_powercycle) holds reset down for 1 s, and a chip that is only given 50 ms comes up
 * half-way and never answers on the bus -- which is what this driver used to do.
 */
static void
touch_reset(void)
{
	gpio_set(PIN_RESET, false);
	sleep_ms(1000);
	gpio_set(PIN_RESET, true);
	sleep_ms(200);
}

/* Is the chip there and running its firmware? Finds where it keeps the touch report. */
static bool
goodix_probe(bool verbose)
{
	static uint8_t info[GOODIX_MAX_READ];
	uint8_t version[28];
	uint32_t length, offset;

	if (!goodix_read(GOODIX_FW_VERSION, version, sizeof(version))) {
		return false;
	}
	if (!goodix_checksum_ok(version, sizeof(version))) {
		if (verbose) {
			goodix_trace("goodix: no valid firmware version: %02x %02x %02x %02x %02x %02x %02x %02x ... %02x %02x\n",
			    version[0], version[1], version[2], version[3], version[4], version[5], version[6], version[7],
			    version[26], version[27]);
		}
		return false;
	}
	goodix_trace("goodix: chip \"%.6s\", firmware \"%.8s\" %02x.%02x.%02x.%02x, sensor %u\n", (const char *)version,
	    (const char *)version + 10, version[18], version[19], version[20], version[21], version[23]);

	if (!goodix_read(GOODIX_IC_INFO, info, 2)) {
		return false;
	}
	length = le16(info);
	if (length < 40 || length >= GOODIX_MAX_READ || !goodix_read(GOODIX_IC_INFO, info, length) ||
	    !goodix_checksum_ok(info, length)) {
		goodix_trace("goodix: bad chip description (length %u)\n", length);
		return false;
	}
	/* the length, the version (16 bytes), the features (10), four counts, then five lists of 16-bit numbers */
	offset = 2 + 16 + 10 + 4;
	for (int i = 0; i < 5; i++) {
		if (offset >= length) {
			return false;
		}
		offset += 1 + 2u * info[offset];
	}
	if (offset + 48 + 2 > length) {
		goodix_trace("goodix: chip description too short (%u, lists end at %u)\n", length, offset);
		return false;
	}
	touch_address = le32(info + offset + 44);
	command_address = le32(info + offset + 0);      /* (the "misc" part: the command buffer comes first) */
	if (offset + 122 + 20 + 2 <= length) {
		uint16_t x = le16(info + offset + 122 + 16), y = le16(info + offset + 122 + 18);

		if (x && y) {
			max_x = x;
			max_y = y;
		}
	}
	goodix_trace("goodix: touch report at %#x, coordinates up to %u x %u\n", touch_address, max_x, max_y);
	return touch_address != 0;
}

/*
 * A command to the chip (Android's brl_send_cmd(): goodix_brl_hw.c of the phone's kernel): sixteen
 * bytes at the command address -- state, acknowledgement, length, command, its data, and the sum of
 * the bytes from the length on -- then the acknowledgement looked for, 0x80 when done.
 */
#define GOODIX_CMD_HIGH_RATE    0xc0            /* data 1: report 480 times a second instead of 240 (Xiaomi's game mode) */
#define GOODIX_ACK_OK           0x80
#define GOODIX_ACK_BUSY         0x02

static bool
goodix_command(uint8_t command, uint8_t data)
{
	uint8_t buffer[16], answer[16];
	uint32_t sum;

	if (command_address == 0) {
		return false;
	}
	memset(buffer, 0, sizeof(buffer));
	buffer[2] = 5;
	buffer[3] = command;
	buffer[4] = data;
	sum = buffer[2] + buffer[3] + buffer[4];
	buffer[5] = (uint8_t)sum;
	buffer[6] = (uint8_t)(sum >> 8);
	for (int attempt = 0; attempt < 6; attempt++) {
		if (!goodix_write(command_address, buffer, sizeof(buffer))) {
			return false;
		}
		for (int look = 0; look < 6; look++) {
			if (!goodix_read(command_address, answer, sizeof(answer))) {
				return false;
			}
			if (answer[1] == GOODIX_ACK_OK) {
				return true;
			}
			sleep_ms(1);
			if (answer[1] != GOODIX_ACK_BUSY && answer[1] != 0) {
				break;
			}
		}
	}
	return false;
}

/* What has been seen so far: said once a minute, so that the end of the log always tells. */
static struct {
	uint32_t polls, reports, touches, bad, last_x, last_y;
} seen;

/* Which fingers were down in the last report, and where. */
static struct {
	bool down, seen;
	uint32_t x, y;
} contact[GOODIX_MAX_TOUCHES];
static uint32_t flip;           /* boot-arg touch_flip: 1 = mirror left-right, 2 = mirror top-bottom */

static void
goodix_report(const uint8_t *touches, uint32_t count)
{
	static unsigned shown;

	for (int i = 0; i < GOODIX_MAX_TOUCHES; i++) {
		contact[i].seen = false;
	}
	for (uint32_t i = 0; i < count; i++) {
		const uint8_t *t = touches + 8 * i;
		uint32_t id = t[0] >> 4, kind = t[0] & 0xf;
		uint32_t x = le16(t + 2), y = le16(t + 4);

		if (id >= GOODIX_MAX_TOUCHES || kind == 1 || kind == 3) {       /* 1 and 3: a stylus */
			continue;
		}
		if (shown < 40) {
			shown++;
			goodix_trace("goodix: finger %u at %u, %u (of %u x %u)\n", id, x, y, max_x, max_y);
		}
		seen.touches++;
		seen.last_x = x;
		seen.last_y = y;
		x = x >= max_x ? 65535 : x * 65535 / max_x;
		y = y >= max_y ? 65535 : y * 65535 / max_y;
		if (flip & 1) {
			x = 65535 - x;
		}
		if (flip & 2) {
			y = 65535 - y;
		}
		contact[id].seen = true;
		if (!contact[id].down) {
			annibale_touch_post(ANNIBALE_TOUCH_DOWN, id, x, y);
		} else if (contact[id].x != x || contact[id].y != y) {
			annibale_touch_post(ANNIBALE_TOUCH_MOVE, id, x, y);
		}
		contact[id].down = true;
		contact[id].x = x;
		contact[id].y = y;
	}
	/* a finger that is no longer in the report has lifted */
	for (uint32_t id = 0; id < GOODIX_MAX_TOUCHES; id++) {
		if (contact[id].down && !contact[id].seen) {
			contact[id].down = false;
			annibale_touch_post(ANNIBALE_TOUCH_UP, id, contact[id].x, contact[id].y);
		}
	}
}

/* Read the report if there is one, and tell the chip it has been read. */
static void
goodix_poll(void)
{
	static uint8_t report[8 + 8 * GOODIX_MAX_TOUCHES + 2];
	static unsigned bad;
	const uint8_t zero = 0;
	const uint32_t first = 8 + 8 * 2 + 2;           /* the header and two fingers: all there is, most of the time */
	uint32_t count;

	seen.polls++;
	if (!goodix_read(touch_address, report, first) || report[0] == 0) {
		return;
	}
	seen.reports++;
	count = report[2] & 0xf;
	if ((report[0] & GOODIX_STATUS_TOUCH) && count > 2 && count <= GOODIX_MAX_TOUCHES &&
	    !goodix_read(touch_address + 8, report + 8, 8 * count + 2)) {
		return;
	}
	goodix_write(touch_address, &zero, 1);
	if (!goodix_checksum_ok(report, 8)) {
		seen.bad++;
		if (bad++ < 8) {
			goodix_trace("goodix: bad report header: %02x %02x %02x %02x %02x %02x %02x %02x\n", report[0], report[1],
			    report[2], report[3], report[4], report[5], report[6], report[7]);
		}
		return;
	}
	if (report[0] & GOODIX_STATUS_REQUEST) {
		if ((report[2] & 0xf) == GOODIX_REQUEST_RESET || report[2] == GOODIX_REQUEST_RESET) {
			goodix_trace("goodix: the chip asks to be reset\n");
			touch_reset();
		}
		return;
	}
	if (!(report[0] & GOODIX_STATUS_TOUCH)) {
		return;
	}
	if (count > GOODIX_MAX_TOUCHES || (count && !goodix_checksum_ok(report + 8, count * 8 + 2))) {
		seen.bad++;
		if (bad++ < 8) {
			goodix_trace("goodix: bad report (%u touches)\n", count);
		}
		return;
	}
	goodix_report(report + 8, count);
}

/* ---- the FocalTech FT3680 chip --------------------------------------------------------------------- */

/*
 * FTS 5.x SPI framing from sm8350-kernel-OKX drivers/input/touchscreen/focaltech_3680/
 * focaltech_spi.c (verbatim):
 *   TX[0] = register address (writebuf[0] / cmd[0])
 *   TX[1] = FOCALTECH_READ_CTRL (0xA0 = READ_CMD, CRC_EN set) or FOCALTECH_WRITE_CTRL (0x00)
 *   TX[2..3] = data length BE (for read: datalen; for write: writelen - 1)
 *   TX[4..6] = three dummy bytes (SPI_DUMMY_BYTE)
 *   TX[7..7+len-1] = write data (empty on read; chip drives MISO here)
 *   TX[last-1..last] = CRC-16/Kermit of the data bytes, little-endian (only when READ_CMD or
 *                     when a vendor WRITE op needs CRC; vendor WRITE_CMD = 0x00 has no CRC)
 * SPI_HEADER_LENGTH = 4 + SPI_DUMMY_BYTE = 7.
 */
#define FOCALTECH_READ_CTRL         0xa0		/* READ_CMD = 0x80 | DATA_CRC_EN(0x20) */
#define FOCALTECH_WRITE_CTRL        0x00		/* WRITE_CMD, no CRC on TX */
#define FOCALTECH_CHIP_ID_H         0xa3
#define FOCALTECH_CHIP_ID_L         0x9f
#define FOCALTECH_TOUCH_DATA        0x01		/* the touch report lives at this address */
#define FOCALTECH_MAX_TOUCHES       10
#define FOCALTECH_TOUCH_REPORT_LEN  (2 + 6 * FOCALTECH_MAX_TOUCHES)
#define FOCALTECH_MAX_TRANSFER      (7 + FOCALTECH_TOUCH_REPORT_LEN + 2)

static uint8_t focaltech_tx[FOCALTECH_MAX_TRANSFER], focaltech_rx[FOCALTECH_MAX_TRANSFER];

/* CRC-16/Kermit (polynomial 0x8408 reflected, initial 0xffff) -- same as vendor rckit_crc16(). */
static uint16_t
focaltech_crc(const uint8_t *data, uint32_t length)
{
	uint16_t crc = 0xffff;

	for (uint32_t i = 0; i < length; i++) {
		crc ^= data[i];
		for (int bit = 0; bit < 8; bit++) {
			crc = (crc & 1) ? (uint16_t)((crc >> 1) ^ 0x8408) : (uint16_t)(crc >> 1);
		}
	}
	return crc;
}

/*
 * One framed read. The control byte the POCO X5 Pro's FT3680 wants is 0xA0 (read, CRC on); a chip of
 * the same family that does not take the CRC flag answers only to the plain 0x80, and with 0xA0 it
 * leaves the data line alone -- which reads as a bus that stays high. Both are tried, and the one
 * that works is remembered.
 */
static int focaltech_read_mode = -1;            /* -1: not known yet, 0: 0xA0 with CRC, 1: 0x80 */

static bool
focaltech_read(uint8_t address, uint8_t *data, uint32_t length)
{
	static const uint8_t controls[2] = { FOCALTECH_READ_CTRL, FOCALTECH_READ_CTRL & ~0x20u };
	const uint32_t data_offset = 7;
	uint32_t transfer_length = data_offset + length + 2;
	bool answered = false;

	if (length == 0 || transfer_length > sizeof(focaltech_tx)) {
		return false;
	}
	for (int pass = 0; pass < 2; pass++) {
		int mode = focaltech_read_mode >= 0 ? focaltech_read_mode : pass;

		for (int attempt = 0; attempt < 2; attempt++) {
			memset(focaltech_tx, 0, transfer_length);
			memset(focaltech_rx, 0, transfer_length);
			focaltech_tx[0] = address;		/* vendor: TX[0] = cmd[0] = reg address */
			focaltech_tx[1] = controls[mode];	/* vendor: TX[1] = ctrl */
			focaltech_tx[2] = (uint8_t)(length >> 8);
			focaltech_tx[3] = (uint8_t)length;
			if (!spi_transfer(focaltech_tx, focaltech_rx, transfer_length)) {
				sleep_us(150);
				continue;
			}
			/* vendor: bit 7 of status (rx[3]) is BUSY, bit 5 is CRC error */
			if (!(focaltech_rx[3] & 0xa0)) {
				if (mode == 0) {
					uint16_t expected = focaltech_crc(focaltech_rx + data_offset, length);
					uint16_t received = (uint16_t)(focaltech_rx[data_offset + length] |
					    focaltech_rx[data_offset + length + 1] << 8);

					if (expected == received) {
						memcpy(data, focaltech_rx + data_offset, length);
						answered = true;
					}
				} else {
					bool blank = true;

					for (uint32_t i = 0; i < length; i++) {
						blank &= focaltech_rx[data_offset + i] == 0 ||
						    focaltech_rx[data_offset + i] == 0xff;
					}
					if (!blank) {
						memcpy(data, focaltech_rx + data_offset, length);
						answered = true;
					}
				}
			}
			if (answered) {
				if (focaltech_read_mode < 0) {
					focaltech_read_mode = mode;
					goodix_trace("focaltech: the chip reads with control %#x (status %#x, %u bytes)\n",
					    controls[mode], focaltech_rx[3], length);
				}
				sleep_us(150);		/* minimum CS-high time in the vendor driver */
				return true;
			}
			sleep_us(150);
		}
		if (focaltech_read_mode >= 0) {
			break;			/* the mode is known: no point trying the other one */
		}
	}
	return false;
}

/*
 * Vendor fts_write: no CRC on TX. For a 1-byte "command" (length == 0) the frame is just the
 * four header bytes { addr, 0x00, 0x00, 0x00 } with no dummy and no data. For length > 0 the
 * three dummy bytes precede the data: { addr, 0x00, lenH, lenL, 0, 0, 0, data... }. The chip
 * drives the "status" byte on rx[3] -- bits 7 and 5 set mean busy or CRC error (vendor retries
 * SPI_RETRY_NUMBER = 3 times on failure before giving up).
 */
static bool
focaltech_write(uint8_t address, const uint8_t *data, uint32_t length)
{
	uint32_t transfer_length;

	if (length == 0) {
		transfer_length = 4;
	} else {
		transfer_length = 7 + length;
	}
	if (transfer_length > sizeof(focaltech_tx)) {
		return false;
	}
	memset(focaltech_tx, 0, transfer_length);
	focaltech_tx[0] = address;
	focaltech_tx[1] = FOCALTECH_WRITE_CTRL;
	focaltech_tx[2] = (uint8_t)(length >> 8);
	focaltech_tx[3] = (uint8_t)length;
	if (data && length > 0) {
		memcpy(focaltech_tx + 7, data, length);
	}
	for (int attempt = 0; attempt < 3; attempt++) {
		if (spi_transfer(focaltech_tx, focaltech_rx, transfer_length) &&
		    !(focaltech_rx[3] & 0xa0)) {
			sleep_us(150);
			return true;
		}
		sleep_us(150);
	}
	return false;
}

/*
 * Vendor fts_fwupg_get_boot_state() reads the chip's "boot ID" via the FT boot-ROM protocol:
 *   TX = { 0x55, 0xAA }                 (FTS_CMD_START1, FTS_CMD_START2 -- enter boot)
 *   wait FTS_CMD_START_DELAY = 12 ms
 *   TX = { 0x90 }, RX = 2 bytes         (FTS_CMD_READ_ID, incell cmd length)
 * If the two RX bytes are the chip's boot ID (0x56 0x62 for FT3680), firmware is present and
 * valid in flash but has not yet been started; the host must issue FTS_CMD_FIRMWARE_START
 * (0x08) to make the boot ROM jump to it.
 */
#define FTS_CMD_START1              0x55
#define FTS_CMD_START2              0xaa
#define FTS_CMD_START_DELAY         12		/* ms, between enter-boot and first command */
#define FTS_CMD_READ_BOOT_ID        0x90

/* Boot-ROM commands for firmware (pramboot) upload, from focaltech_3658u/focaltech_flash.h. */
#define FTS_ROMBOOT_CMD_SET_PRAM_ADDR   0xad
#define FTS_ROMBOOT_CMD_WRITE           0xae
#define FTS_ROMBOOT_CMD_START_APP       0x08
#define FTS_FLASH_PACKET_LENGTH         32		/* bytes per PRAM write */

#include "annibale_focaltech_fw.h"

/*
 * Vendor fts_read_bootid(): send { 0x55, 0xAA } as a 2-byte framed write (treated as a write of
 * one data byte 0xAA to register 0x55), wait 12 ms, then do a framed read of 2 bytes at
 * register 0x90. The chip answers with its ROM ID (0x56 0x62 for FT3680) if it is sitting in
 * the boot ROM waiting for a firmware download.
 */
static bool
focaltech_read_boot_id(uint8_t *high, uint8_t *low)
{
	uint8_t aa = FTS_CMD_START2;
	uint8_t out[2] = { 0 };
	bool ok;

	if (!focaltech_write(FTS_CMD_START1, &aa, 1)) {
		return false;
	}
	sleep_ms(12);			/* FTS_CMD_START_DELAY */
	ok = focaltech_read(FTS_CMD_READ_BOOT_ID, out, 2);
	*high = out[0];
	*low  = out[1];
	return ok;
}

/*
 * Vendor fts_wait_tp_to_valid: poll chip ID for up to TIMEOUT_READ_REG (1 s) at 200 ms steps.
 *
 * The vendor driver compares against one chip's two ID bytes (0x56 0x62 is the FT3680 of the POCO X5
 * Pro). The Xiaomi 11 Ultra carries a different part of the same family, so any answer that comes
 * back through the framed read -- which checks a CRC-16 over the data -- counts as "the chip is
 * running": a reading that is all zeros or all ones is the bus floating, and no CRC can pass then.
 */
static bool
focaltech_wait_valid(uint8_t *high, uint8_t *low)
{
	for (int attempt = 0; attempt < 5; attempt++) {
		uint8_t id_high = 0, id_low = 0;
		bool read_high = focaltech_read(FOCALTECH_CHIP_ID_H, &id_high, 1);
		bool read_low = focaltech_read(FOCALTECH_CHIP_ID_L, &id_low, 1);

		if (read_high && id_high != 0x00 && id_high != 0xff) {
			*high = id_high;
			*low = read_low ? id_low : 0;
			goodix_trace("focaltech: the chip answers with ID %02x %02x after %d attempt(s)%s\n", id_high, id_low,
			    attempt + 1, (id_high == 0x56 && id_low == 0x62) ? " (FT3680)" : "");
			return true;
		}
		if (attempt == 0) {
			goodix_trace("focaltech: no chip ID yet: %02x %02x (the two reads %s, %s)\n", id_high, id_low,
			    read_high ? "answered" : "failed", read_low ? "answered" : "failed");
		}
		sleep_ms(200);			/* vendor INTERVAL_READ_REG */
	}
	return false;
}

/*
 * Reset the chip and send 0x55/0xAA to put it in boot ROM, as vendor fts_get_ic_information
 * does. Try up to 3 times with escalating settle delays (12, 20, 28 ms). Returns true if the
 * chip is sitting in its boot ROM, with { 0x56, 0x62 } read back from the boot-ID register.
 */
static bool
focaltech_enter_boot_rom(void)
{
	uint8_t boot_high = 0, boot_low = 0;

	for (int cnt = 0; cnt < 3; cnt++) {
		gpio_set(PIN_RESET, false);
		sleep_ms(1);
		gpio_set(PIN_RESET, true);
		sleep_ms(FTS_CMD_START_DELAY + cnt * 8);
		if (focaltech_read_boot_id(&boot_high, &boot_low) &&
		    boot_high == 0x56 && boot_low == 0x62) {
			goodix_trace("focaltech: in boot ROM after reset %d\n", cnt);
			return true;
		}
		goodix_trace("focaltech: boot ID attempt %d: %02x %02x (not 56 62)\n", cnt, boot_high, boot_low);
	}
	return false;
}

/*
 * Download the embedded firmware (pramboot + application) into the chip's PRAM via the boot
 * ROM's SPI_V2 upload protocol. Each 32-byte packet is sent as two framed writes: first set
 * the PRAM destination address (SET_PRAM_ADDR + 3 BE address bytes), then WRITE + data bytes.
 */
static bool
focaltech_write_pram(const uint8_t *buf, uint32_t len)
{
	uint8_t addr_bytes[3];

	for (uint32_t offset = 0; offset < len; offset += FTS_FLASH_PACKET_LENGTH) {
		uint32_t chunk = FTS_FLASH_PACKET_LENGTH;
		if (offset + chunk > len) {
			chunk = len - offset;
		}
		addr_bytes[0] = (uint8_t)(offset >> 16);
		addr_bytes[1] = (uint8_t)(offset >> 8);
		addr_bytes[2] = (uint8_t)offset;
		if (!focaltech_write(FTS_ROMBOOT_CMD_SET_PRAM_ADDR, addr_bytes, 3)) {
			goodix_trace("focaltech: PRAM address write failed at offset %u\n", offset);
			return false;
		}
		if (!focaltech_write(FTS_ROMBOOT_CMD_WRITE, buf + offset, chunk)) {
			goodix_trace("focaltech: PRAM data write failed at offset %u\n", offset);
			return false;
		}
	}
	return true;
}

static bool
focaltech_start_app(void)
{
	uint8_t cmd = FTS_ROMBOOT_CMD_START_APP;

	return focaltech_write(cmd, NULL, 0);
}

/*
 * Full chip bring-up: look for an already-running firmware; if none, reset to boot ROM and
 * download the embedded firmware into PRAM; then start it and wait for runtime to come up.
 */
static bool
focaltech_probe(bool verbose)
{
	uint8_t high = 0, low = 0;

	/* Maybe firmware is already running (previous session, warm boot). */
	if (focaltech_wait_valid(&high, &low)) {
		return true;
	}

	if (!focaltech_enter_boot_rom()) {
		if (verbose) {
			goodix_trace("focaltech: chip not in boot ROM; last read runtime %02x %02x\n", high, low);
		}
		return false;
	}

	/*
	 * The firmware in redwood_focaltech_fw.h is the FT3680's. On the star the chip is a different
	 * part of the family, and its own flash holds a firmware that works: a chip that comes up in its
	 * boot ROM wants a download we have no build of, so leave it alone rather than put the wrong
	 * image in its PRAM.
	 */
	if (site->phys == 0x00a8c000) {
		goodix_trace("focaltech: the chip is in its boot ROM; the firmware in this kernel is not for it: not downloading\n");
		return false;
	}

	goodix_trace("focaltech: downloading %u bytes of firmware to PRAM...\n", FOCALTECH_FW_LENGTH);
	if (!focaltech_write_pram(focaltech_fw, FOCALTECH_FW_LENGTH)) {
		goodix_trace("focaltech: PRAM download failed\n");
		return false;
	}
	goodix_trace("focaltech: PRAM download complete; starting application\n");
	if (!focaltech_start_app()) {
		goodix_trace("focaltech: start-app command failed\n");
		return false;
	}
	sleep_ms(300);			/* firmware needs time to initialize all peripherals */

	if (focaltech_wait_valid(&high, &low)) {
		return true;
	}
	if (verbose) {
		goodix_trace("focaltech: firmware did not come up (last runtime read %02x %02x)\n", high, low);
	}
	return false;
}

/* ---- FocalTech touch reports --------------------------------------------------------------------- */

/*
 * Per-chip report layout for FT3680 (vendor focaltech_core.c, FTS_TOUCH_OFF_* offsets):
 *   report[0] = gesture (0 outside gesture mode)
 *   report[1] = (chip_type << 4) | finger_count
 *   report[2 + 6*i + 0] = E_XH:  bits 7..6 = event (0 = down, 1 = up, 2 = contact)
 *                                bits 3..0 = x bits 14..11
 *   report[2 + 6*i + 1] = XL:    x bits 10..3
 *   report[2 + 6*i + 2] = ID_YH: bits 7..4 = finger id, bits 3..0 = y bits 14..11
 *   report[2 + 6*i + 3] = YL:    y bits 10..3
 *   report[2 + 6*i + 4] = PRE:   bits 7..5 = x bits 2..0, bits 4..2 = y bits 2..0
 *                                (also the pressure byte -- the lowest bits of each 15-bit axis
 *                                 are packed in with it)
 *   report[2 + 6*i + 5] = AREA:  touch area / major
 * Coordinates are 15-bit "super-high resolution" sub-pixel values; the touch panel's actual
 * extent is reported through the device tree as x_max/y_max (10800 x 24000 for redwood).
 */
#define FOCALTECH_EVENT_DOWN        0
#define FOCALTECH_EVENT_UP          1
#define FOCALTECH_EVENT_CONTACT     2

static struct {
	bool down, seen;
	uint32_t x, y;
} focaltech_contact[FOCALTECH_MAX_TOUCHES];

static void
focaltech_contact_update(uint32_t id, uint32_t event, uint32_t x, uint32_t y,
    uint32_t max_report_x, uint32_t max_report_y)
{
	static unsigned shown;
	uint32_t raw_x, raw_y;

	if (id >= FOCALTECH_MAX_TOUCHES || max_report_x == 0 || max_report_y == 0) {
		return;
	}
	if (event == FOCALTECH_EVENT_UP) {
		focaltech_contact[id].seen = true;
		if (focaltech_contact[id].down) {
			focaltech_contact[id].down = false;
			annibale_touch_post(ANNIBALE_TOUCH_UP, id, focaltech_contact[id].x, focaltech_contact[id].y);
		}
		return;
	}
	seen.touches++;
	raw_x = x;
	raw_y = y;
	switch (flip) {
	case 1: x = max_report_x - 1 - x; break;
	case 2: y = max_report_y - 1 - y; break;
	case 3: x = max_report_x - 1 - x; y = max_report_y - 1 - y; break;
	}
	x = (uint32_t)(((uint64_t)x * 65535) / (max_report_x - 1));
	y = (uint32_t)(((uint64_t)y * 65535) / (max_report_y - 1));
	seen.last_x = x;
	seen.last_y = y;
	focaltech_contact[id].seen = true;
	if (!focaltech_contact[id].down) {
		focaltech_contact[id].down = true;
		annibale_touch_post(ANNIBALE_TOUCH_DOWN, id, x, y);
	} else if (focaltech_contact[id].x != x || focaltech_contact[id].y != y) {
		annibale_touch_post(ANNIBALE_TOUCH_MOVE, id, x, y);
	}
	focaltech_contact[id].x = x;
	focaltech_contact[id].y = y;
	if (shown++ < 8) {
		goodix_trace("focaltech: finger %u %s: report %u, %u of %u x %u -> %u, %u of 65535\n", id,
		    event == FOCALTECH_EVENT_DOWN ? "down" : "move", raw_x, raw_y, max_report_x, max_report_y, x, y);
	}
}

/*
 * The panel size the reports are measured against: "fts,x-max"/"fts,y-max" of the phone's device
 * tree. The POCO X5 Pro reports in the panel's super-high-resolution units (10800 x 24000); the
 * Xiaomi 11 Ultra reports screen pixels (1440 x 3200). Boot-args fts_max_x=/fts_max_y= override.
 */
static uint32_t focaltech_max_x = 1440, focaltech_max_y = 3200;

static void
focaltech_report(const uint8_t *report)
{
	uint32_t count = report[1] & 0x0f;

	for (uint32_t i = 0; i < FOCALTECH_MAX_TOUCHES; i++) {
		focaltech_contact[i].seen = false;
	}
	for (uint32_t i = 0; i < FOCALTECH_MAX_TOUCHES; i++) {
		const uint8_t *touch = report + 2 + 6 * i;
		uint32_t id = (touch[2] >> 4) & 0x0f;
		uint32_t event, x, y;

		if (id >= FOCALTECH_MAX_TOUCHES) {
			break;			/* no more valid slots in this report */
		}
		event = (touch[0] >> 6) & 0x3;
		x = ((uint32_t)(touch[0] & 0x0f) << 11) | ((uint32_t)touch[1] << 3) |
		    ((uint32_t)touch[4] >> 5);
		y = ((uint32_t)(touch[2] & 0x0f) << 11) | ((uint32_t)touch[3] << 3) |
		    (((uint32_t)touch[4] & 0x1c) >> 2);
		focaltech_contact_update(id, event, x, y, focaltech_max_x, focaltech_max_y);
	}
	(void)count;
	/* Fingers not in this report are up (vendor driver uses a bitmap; we remember explicitly). */
	for (uint32_t i = 0; i < FOCALTECH_MAX_TOUCHES; i++) {
		if (!focaltech_contact[i].seen && focaltech_contact[i].down) {
			focaltech_contact[i].down = false;
			annibale_touch_post(ANNIBALE_TOUCH_UP, i, focaltech_contact[i].x, focaltech_contact[i].y);
		}
	}
}

static void
focaltech_poll(void)
{
	static uint8_t report[FOCALTECH_TOUCH_REPORT_LEN];
	static unsigned bad;

	seen.polls++;
	if (!focaltech_read(FOCALTECH_TOUCH_DATA, report, sizeof(report))) {
		seen.bad++;
		if (bad++ < 8) {
			goodix_trace("focaltech: SPI read failed for touch report\n");
		}
		return;
	}
	seen.reports++;
	focaltech_report(report);
}

/* ---- the STM FTS K2 ("st,spi") -------------------------------------------------------------------- */
/*
 * The Xiaomi 11 Ultra's panel is an STM FTS K2, not the Goodix GT9916 or FocalTech FT3680 this
 * driver was written for. Disassembly of the vendor's /vendor/lib/modules/fts_touch_spi_k2.ko
 * gives the framing, and a live read of the chip confirms it:
 *
 *   fts_writeReadU8UX(cmd, addrLen, address, out, n, 1)
 *     tx: [cmd][address as addrLen big-endian bytes], then (n+1) clocks with MOSI low
 *     rx: the chip echoes the command one byte late, then one dummy byte, then n data bytes
 *     out = rxbuf + 1 (the first byte of the read phase is that dummy)
 *
 * The vendor builds one spi_message of two transfers. GENI asserts CS for only one M_CMD0
 * command, so here the two are joined into a single full-duplex frame with CS held low all the
 * way through. stm_tail (found by stm_probe(), boot-arg stm_tail=N overrides) is the number of
 * bytes between the last command byte and the first data byte.
 *
 * readSysInfo: fts_writeReadU8UX(0xa7, 2, 0x0000, info, 208, 1), then info[0]==0xa5 &&
 * info[1]==0x01. fts_event_handler: fts_writeReadU8UX(0x87, 0, 0, head, 8, 1); head[7]&0x1f
 * events follow, each eight bytes, read with a second 0x87 command.
 */
#define STM_CMD_READ            0xa7
#define STM_CMD_EVENTS          0x87
#define STM_READ_MAX            256
#define STM_MAX_EVENTS          10
#define STM_MAX_TOUCHES         10
/*
 * Backstop for a contact that simply stops appearing. The real lift is the subtype-4/5 event;
 * this only catches a lost frame. It must stay well above a report interval: at 60 ms a slow
 * one-finger drag between two reports was being lifted and re-pressed, which broke the gesture
 * while two fingers (reporting alternately) stayed down. 250 ms is several missed reports.
 */
#define STM_UP_TIMEOUT_US       250000

static uint8_t stm_tx[1 + 2 + 1 + STM_READ_MAX];
static uint8_t stm_rx[1 + 2 + 1 + STM_READ_MAX];
static uint8_t stm_raw[1 + 2 + 1 + STM_READ_MAX];
static uint32_t stm_tail = 1;           /* dummy bytes between the command and the data */
static bool stm_tail_forced;             /* boot-arg stm_tail=N was given: do not auto-detect */

static struct {
	bool down;
	uint32_t x, y;
	uint64_t last;                  /* when this finger was last seen, in microseconds */
} stm_contact[STM_MAX_TOUCHES];

static uint64_t
stm_micros(void)
{
	uint64_t ns;

	absolutetime_to_nanoseconds(mach_absolute_time(), &ns);
	return ns / 1000;
}

/* One CS-low frame: the command, then n+1 clocks with MOSI low. Keep the whole MISO stream. */
static bool
stm_frame(uint8_t cmd, unsigned addr_len, uint32_t address, uint32_t n,
    uint8_t *raw, uint32_t *raw_len)
{
	uint32_t header = 1 + addr_len, total = header + 1 + n;

	if (addr_len > 2 || n > STM_READ_MAX || total > sizeof(stm_tx)) {
		return false;
	}
	memset(stm_tx, 0, total);
	memset(stm_rx, 0, total);
	stm_tx[0] = cmd;
	for (unsigned i = 0; i < addr_len; i++) {
		stm_tx[1 + i] = (uint8_t)(address >> (8 * (addr_len - 1 - i)));
	}
	if (!spi_transfer(stm_tx, stm_rx, total)) {
		return false;
	}
	memcpy(raw, stm_rx, total);
	*raw_len = total;
	return true;
}

static bool
stm_read(uint8_t cmd, unsigned addr_len, uint32_t address, uint8_t *out, uint32_t n)
{
	uint32_t len, header = 1 + addr_len, at = header + stm_tail;

	if (!stm_frame(cmd, addr_len, address, n, stm_raw, &len) || at + n > len) {
		return false;
	}
	if (out) {
		memcpy(out, stm_raw + at, n);
	}
	return true;
}

static void
stm_bytes(const char *what, const uint8_t *p, uint32_t n)
{
	char line[512];
	int off = snprintf(line, sizeof(line), "stm: %s (%u bytes):", what, n);

	for (uint32_t i = 0; i < n && off > 0 && (size_t)off < sizeof(line) - 4; i++) {
		off += snprintf(line + off, sizeof(line) - (size_t)off, " %02x", p[i]);
	}
	goodix_trace("%s\n", line);            /* goodix_trace adds the newline loader_log_line does not */
}

/*
 * The vendor's senseOn() is setScanMode(0, 1), which puts {0xa0, 0x00, 0x01} on the bus: command
 * 0xa0, scan mode 0 (normal), 1 = start. senseOff() sends the same frame with a trailing zero.
 *
 * This is the step that was missing. The controller answers the system-info read perfectly and
 * reports controller-ready after the reset, but it does not scan the panel until the host asks:
 * the poll loop read nothing but zeros because the chip was idle, not because the framing was
 * wrong. An idle chip still answers 0x87 with an empty event header, which is exactly what the
 * earlier log showed (head 00 ... 00, 0 events).
 */
static bool
stm_sense_on(void)
{
	static const uint8_t cmd[3] = { 0xa0, 0x00, 0x01 };
	uint8_t rx[3];

	memset(rx, 0, sizeof(rx));
	if (!spi_transfer(cmd, rx, sizeof(cmd))) {
		goodix_trace("stm: the sense-on command could not be sent\n");
		return false;
	}
	goodix_trace("stm: sense on (a0 00 01) -> %02x %02x %02x\n", rx[0], rx[1], rx[2]);
	sleep_ms(50);                   /* the vendor waits a frame before the first poll */
	return true;
}

/* Is the chip there? Read the system info and find where the read phase begins. */
static bool
stm_probe(bool verbose)
{
	uint8_t raw[64], events[16];
	uint32_t len, header = 3, i, found = 0;

	if (!stm_frame(STM_CMD_READ, 2, 0x0000, 32, raw, &len)) {
		goodix_trace("stm: the system-info read did not complete\n");
		return false;
	}
	stm_bytes("system-info frame", raw, len);
	/* 0xa5 0x01 is the system-info header the vendor's readSysInfo insists on. */
	for (i = 1; i + 1 < len; i++) {
		if (raw[i] == 0xa5 && raw[i + 1] == 0x01) {
			found = i;
			break;
		}
	}
	if (!found) {
		goodix_trace("stm: no 0xa5 0x01 system-info header in that frame\n");
		return false;
	}
	if (!stm_tail_forced) {
		stm_tail = found - header;
		if (stm_tail > 4) {
			stm_tail = 1;
		}
	}
	{
		uint32_t at = header + stm_tail;

		goodix_trace("stm: the read phase starts at rx[%u] (%u byte(s) after the command)\n", at, stm_tail);
		stm_bytes("system info", raw + at, len - at > 32 ? 32 : len - at);
		if (len >= at + 18) {
			const uint8_t *info = raw + at;

			/* readSysInfo's u16 fields: chip id at +10, firmware version at +16 (little endian). */
			goodix_trace("stm: chip id %#x, firmware %#x (STM FTS K2 system info)\n",
			    (unsigned)(info[10] | info[11] << 8), (unsigned)(info[16] | info[17] << 8));
		}
	}

	/* The same physical offset has to hold for the event command: show its raw frame too. This
	 * read also consumes the controller-ready event the chip raises after the reset. */
	if (stm_frame(STM_CMD_EVENTS, 0, 0, 8, events, &len)) {
		stm_bytes("event frame", events, len);
	}
	/* Now let it scan; without this the chip stays idle for the rest of the boot. */
	if (!stm_sense_on()) {
		return false;
	}
	(void)verbose;
	return true;
}

static void
stm_contact_update(unsigned id, uint32_t x, uint32_t y)
{
	static unsigned reports;
	uint32_t mx = focaltech_max_x, my = focaltech_max_y;

	if (id >= STM_MAX_TOUCHES || !mx || !my) {
		return;
	}
	if (x > mx) {
		x = mx;
	}
	if (y > my) {
		y = my;
	}
	switch (flip) {
	case 1: x = mx - x; break;
	case 2: y = my - y; break;
	case 3: x = mx - x; y = my - y; break;
	}
	x = (uint32_t)(((uint64_t)x * 65535) / mx);
	y = (uint32_t)(((uint64_t)y * 65535) / my);
	seen.last_x = x;
	seen.last_y = y;
	stm_contact[id].last = stm_micros();
	seen.touches++;
	if (!stm_contact[id].down) {
		stm_contact[id].down = true;
		annibale_touch_post(ANNIBALE_TOUCH_DOWN, id, x, y);
		if (reports++ < 40) {
			goodix_trace("stm: down id %u at %u %u\n", id, x, y);
		}
	} else if (stm_contact[id].x != x || stm_contact[id].y != y) {
		annibale_touch_post(ANNIBALE_TOUCH_MOVE, id, x, y);
		if (reports++ < 40) {
			goodix_trace("stm: move id %u at %u %u\n", id, x, y);
		}
	}
	stm_contact[id].x = x;
	stm_contact[id].y = y;
}

/* A finger that has not appeared for a while has lifted. */
static void
stm_expire(void)
{
	uint64_t now = stm_micros();

	for (unsigned i = 0; i < STM_MAX_TOUCHES; i++) {
		if (stm_contact[i].down && now - stm_contact[i].last > STM_UP_TIMEOUT_US) {
			stm_contact[i].down = false;
			annibale_touch_post(ANNIBALE_TOUCH_UP, i, stm_contact[i].x, stm_contact[i].y);
		}
	}
}

/*
 * One event is eight bytes (fts_enter_pointer_event_handler of the vendor driver):
 *   e[0]       0x13 enter, 0x23 motion, 0x33 leave; 0x03 controller ready, 0x43 status, 0xf3 error
 *   e[1]       (touch id << 4) | subtype -- the subtype is 1 on every frame this panel sends,
 *              so the frame type in e[0] is what separates a press from a lift
 *   e[2], e[3] x = e[2] | ((e[3] & 0x0f) << 8)
 *   e[3], e[4] y = (e[4] << 4) | (e[3] >> 4)
 *   e[5..7]    pressure, area, counter
 *
 * A real capture settles it: 13 enter, 171 motion, 13 leave frames, every one with subtype 1,
 * so lifting is e[0] == 0x33 and nothing else. Guessing subtype 4/5 additionally mistook the
 * 0x43 status frame for a lift -- and 0x43's payload is the echo of the last command
 * ("a0 00 01" after sense-on), which then became a phantom finger at (160, 16) on every boot.
 * Everything that is not one of the three pointer frames is dropped before it is decoded.
 */
static void
stm_event(const uint8_t *e)
{
	static unsigned shown, ups;
	unsigned id = e[1] >> 4, subtype = e[1] & 0xf;
	uint32_t x = (uint32_t)e[2] | ((uint32_t)(e[3] & 0x0f) << 8);
	uint32_t y = ((uint32_t)e[4] << 4) | (e[3] >> 4);

	if (shown++ < 200) {
		goodix_trace("stm: event %02x %02x %02x %02x %02x %02x %02x %02x: id %u sub %u x %u y %u\n",
		    e[0], e[1], e[2], e[3], e[4], e[5], e[6], e[7], id, subtype, x, y);
	}
	/* controller-ready, status and error frames carry no contact: drop them before decoding */
	if (e[0] != 0x13 && e[0] != 0x23 && e[0] != 0x33) {
		return;
	}
	if (id >= STM_MAX_TOUCHES) {
		return;
	}
	if (e[0] == 0x33) {
		if (stm_contact[id].down) {
			stm_contact[id].down = false;
			annibale_touch_post(ANNIBALE_TOUCH_UP, id, stm_contact[id].x, stm_contact[id].y);
			if (ups++ < 40) {
				goodix_trace("stm: up id %u\n", id);
			}
		}
		return;
	}
	if (!x && !y) {
		return;
	}
	stm_contact_update(id, x, y);
}

/*
 * Drain the controller one event at a time, exactly like the vendor's pollForEvent():
 *
 *   0x87 returns ONE eight-byte event per read. The vendor loops reading eight bytes and stops
 *   when buf[0] is zero, with a short delay between reads. It never looks at buf[7].
 *
 * Reading several events per command and using buf[7] & 0x1f as the count was wrong: buf[7] is
 * the event's own last byte, not a queue length. That mis-sized the reads and, worse, dropped a
 * genuine event whenever its last byte happened to be zero -- which is how a lift got lost and a
 * tap stayed held until the timeout. Now each event is read and dispatched on its own.
 */
static bool
stm_poll(void)
{
	static uint8_t head[8];
	static unsigned bad, ticks;
	bool any = false;

	seen.polls++;
	for (unsigned round = 0; round < STM_MAX_EVENTS * 2; round++) {
		if (!stm_read(STM_CMD_EVENTS, 0, 0, head, sizeof(head))) {
			seen.bad++;
			if (bad++ < 8) {
				goodix_trace("stm: the event read failed\n");
			}
			break;
		}
		seen.reports++;
		/* A short line every couple of seconds: it says the poll loop is alive and shows the raw
		 * event bytes, so a wrong read-phase offset cannot hide a silent chip. */
		if (ticks++ % 250 == 0) {
			goodix_trace("stm: poll %u: head %02x %02x %02x %02x %02x %02x %02x %02x, "
			    "irq %u, %u polls so far\n",
			    ticks - 1, head[0], head[1], head[2], head[3], head[4], head[5], head[6], head[7],
			    gpio_get(PIN_INT), seen.polls);
		}
		if (head[0] == 0) {
			break;          /* the queue is empty */
		}
		any = true;
		stm_event(head);
	}
	stm_expire();
	return any;
}

/* Which touch chip is on this board. */
enum touch_chip { TOUCH_GOODIX, TOUCH_FOCALTECH, TOUCH_STM };
static enum touch_chip touch_chip;

/*
 * The two ID straps that tell a FocalTech from a Goodix panel on the POCO X5 Pro (gpio96 high and
 * gpio68 low). The Xiaomi 11 Ultra reads gpio96 high and gpio68 high and still carries a FocalTech,
 * so the straps only give a hint here -- what decides is which chip answers on the bus.
 */
static enum touch_chip
touch_chip_detect(void)
{
	gpio_configure(PIN_FOCALTECH_ID, 0, PULL_NONE, 2, false);
	gpio_configure(PIN_GOODIX_ID, 0, PULL_NONE, 2, false);
	if (gpio_get(PIN_GOODIX_ID) && !gpio_get(PIN_FOCALTECH_ID)) {
		return TOUCH_FOCALTECH;
	}
	return TOUCH_GOODIX;
}

static bool
chip_probe(bool verbose)
{
	enum touch_chip first = touch_chip;

	/* The star carries an STM FTS K2: neither of the other two protocols can reach it. */
	if (site->phys == 0x00a8c000) {
		if (stm_probe(verbose)) {
			touch_chip = TOUCH_STM;
			return true;
		}
		goodix_trace("goodix: the STM FTS K2 did not answer; trying the other two protocols\n");
	}

	/* the order the straps suggest first; the other chip is tried when that one does not answer */
	for (int attempt = 0; attempt < 2; attempt++) {
		enum touch_chip chip = attempt == 0 ? first :
		    (first == TOUCH_FOCALTECH ? TOUCH_GOODIX : TOUCH_FOCALTECH);

		if (chip == TOUCH_FOCALTECH) {
			if (focaltech_probe(verbose)) {
				touch_chip = TOUCH_FOCALTECH;
				return true;
			}
		} else {
			touch_reset();
			if (goodix_probe(verbose)) {
				touch_chip = TOUCH_GOODIX;
				return true;
			}
		}
		if (attempt == 0) {
			goodix_trace("goodix: no %s chip answered; trying %s\n",
			    first == TOUCH_FOCALTECH ? "focaltech" : "goodix",
			    first == TOUCH_FOCALTECH ? "goodix" : "focaltech");
		}
	}
	return false;
}

static bool
chip_poll(void)
{
	if (touch_chip == TOUCH_STM) {
		return stm_poll();
	}
	if (touch_chip == TOUCH_FOCALTECH) {
		focaltech_poll();
	} else {
		goodix_poll();
	}
	return false;
}

/* ---- all of it together ---------------------------------------------------------------------------- */

/* The two supply switches, set from the phone the serial engine belongs to (bring_up()). */
static unsigned pin_avdd = PIN_AVDD_STAR, pin_vdd = PIN_VDD_STAR;

static void
show_state(const char *when)
{
	goodix_trace("goodix: %s: votes %#x, clocks %#x %#x %#x, rate cfg %#x dfs %#x; pins cs/clk/mosi/miso cfg %#x %#x %#x %#x,"
	    " reset %#x/%u, int %#x/%u, avdd gpio%u %#x/%u, vdd gpio%u %#x/%u, straps %u %u\n", when, rd(GCC_VOTE),
	    rd(GCC_QUP1_M_AHB_CBCR), rd(GCC_QUP1_S_AHB_CBCR), rd(GCC_SE_CBCR), rd(GCC_SE_CFG), rd(GCC_SE_DFSR),
	    rd(GPIO_CFG(PIN_CS)), rd(GPIO_CFG(PIN_CLK)), rd(GPIO_CFG(PIN_MOSI)), rd(GPIO_CFG(PIN_MISO)),
	    rd(GPIO_CFG(PIN_RESET)), rd(GPIO_IO(PIN_RESET)), rd(GPIO_CFG(PIN_INT)), rd(GPIO_IO(PIN_INT)),
	    pin_avdd, rd(GPIO_CFG(pin_avdd)), rd(GPIO_IO(pin_avdd)),
	    pin_vdd, pin_vdd ? rd(GPIO_CFG(pin_vdd)) : 0, pin_vdd ? rd(GPIO_IO(pin_vdd)) : 0,
	    gpio_get(68), gpio_get(96));
}

/*
 * Power the chip up from nothing, in the vendor driver's order.
 *
 *   1.8 V I/O   LDO2 of the PM8350C, through RPMh (both phones)
 *   VDD         star has a second switch of its own, gpio154
 *   AVDD        the analog supply: gpio12 on redwood, gpio132 on star
 *   reset       held low until everything else is up
 *
 * The two regulators of the star are "regulator-fixed" in its device tree, each with one enable gpio
 * and enable-active-high, so driving the pin is all Android's regulator framework does.
 */
static void
power_on(void)
{
	gpio_output(PIN_RESET, false, PULL_UP, 8);
	gpio_configure(PIN_INT, 0, PULL_UP, 8, false);
	if (pin_vdd) {
		gpio_output(pin_vdd, true, PULL_NONE, 2);       /* the chip's own supply first ... */
		sleep_ms(2);
	}
	io_supply_on();
	sleep_ms(3);
	gpio_output(pin_avdd, true, PULL_NONE, 2);              /* ... then the analog one */
	sleep_ms(15);
}

static void
use_engine_pins(void)
{
	gpio_configure(PIN_MISO, spi_function, PULL_NONE, 6, false);
	gpio_configure(PIN_MOSI, spi_function, PULL_NONE, 6, false);
	gpio_configure(PIN_CLK, spi_function, PULL_NONE, 6, false);
	gpio_configure(PIN_CS, spi_function, PULL_NONE, 6, false);
}

static const char *
chip_name(void)
{
	return touch_chip == TOUCH_STM ? "stm" :
	    touch_chip == TOUCH_FOCALTECH ? "focaltech" : "goodix";
}

/*
 * ---- asking the hardware the questions the logs cannot answer -------------------------------------
 *
 * Three things about the star were never confirmed by anything but a guess, and each of them alone is
 * enough to keep the chip silent:
 *
 *   - whether a write to the pin controller takes effect at all, and at which block gpio0 lives;
 *   - which number the pin controller wants for "qup11" (see PIN_FUNCTION_SPI);
 *   - whether the serial engine's own datapath works, independently of the four pins and the chip.
 *
 * The loopback test answers the third without touching anything: with SPI_LOOPBACK set the engine
 * feeds its own transmitter back into its receiver, so bytes that come back are bytes that went
 * through the FIFOs, the packing and the clock divider. A sweep of the function numbers then answers
 * the second, by asking the chip after each one. All of it happens in one boot, and the values that
 * worked are left in place for the rest of the driver.
 */

/* One raw read frame with the four pins muxed to `function`: no retries, no CRC check, no guessing --
 * just what came back. A data line nobody drives reads 00 or ff; a chip reads as something else. */
static bool
bus_sniff(unsigned block, unsigned function)
{
	uint8_t tx[11], rx[11];
	unsigned answered = 0;

	memset(tx, 0, sizeof(tx));
	memset(rx, 0, sizeof(rx));
	tx[0] = FOCALTECH_CHIP_ID_H;                    /* the register the vendor reads first */
	tx[1] = FOCALTECH_READ_CTRL & ~0x20u;           /* read, CRC off: the plain 0x80 */
	tx[2] = 0x00;
	tx[3] = 0x02;                                   /* two bytes back */
	if (!spi_transfer(tx, rx, sizeof(tx))) {
		goodix_trace("goodix: block %u function %2u: the engine could not run the transfer\n", block, function);
		return false;
	}
	for (unsigned i = 4; i < sizeof(rx); i++) {
		if (rx[i] != 0x00 && rx[i] != 0xff) {
			answered++;
		}
	}
	goodix_trace("goodix: block %u function %2u: %02x %02x %02x %02x | %02x %02x %s\n", block, function,
	    rx[0], rx[1], rx[2], rx[3], rx[7], rx[8], answered ? "<-- the chip is driving the line" : "");
	return answered != 0;
}

/*
 * The star's chip is "st,spi" (STM FTS K2), not the FocalTech FT3680 whose framing the driver
 * originally carried. Disassembly of the vendor's fts_touch_spi_k2.ko (readSysInfo, 0x313c) shows
 * a read is a three-byte command {0xA7, addr_hi, addr_lo} sent by itself, after which the chip
 * drives the data bytes: no control byte, no length, no dummy header, no CRC. Try that frame here
 * so a single boot says whether the chip answers at all before the rest of the protocol is ported.
 */
static void
stm_raw_probe(void)
{
	static const uint8_t frames[3][3] = {
		{ 0xa7, 0x00, 0x00 },          /* vendor readSysInfo: system info from address 0 */
		{ 0xa7, 0x00, 0xa3 },          /* the FT3680's chip-id register, as an STM address */
		{ 0x80, 0x00, 0x00 },          /* the "80" the vendor's sysfs command reports */
	};

	for (unsigned i = 0; i < 3; i++) {
		uint8_t tx[16], rx[16];

		memset(tx, 0, sizeof(tx));
		memset(rx, 0, sizeof(rx));
		tx[0] = frames[i][0];
		tx[1] = frames[i][1];
		tx[2] = frames[i][2];
		if (!spi_transfer(tx, rx, sizeof(tx))) {
			goodix_trace("goodix: STM frame %02x %02x %02x: the transfer failed\n",
			    tx[0], tx[1], tx[2]);
			continue;
		}
		goodix_trace("goodix: STM frame %02x %02x %02x -> %02x %02x %02x | %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",
		    tx[0], tx[1], tx[2], rx[0], rx[1], rx[2], rx[3], rx[4], rx[5], rx[6], rx[7],
		    rx[8], rx[9], rx[10], rx[11], rx[12], rx[13], rx[14]);
	}
}

static void
geni_loopback_probe(void)
{
	uint8_t tx[4] = { 0xa5, 0x5a, 0x3c, 0xc3 }, rx[4] = { 0, 0, 0, 0 };
	uint32_t saved = rd(SPI_LOOPBACK);
	bool ok;

	wr(SPI_LOOPBACK, saved | 1);
	ok = geni_transfer(tx, rx, sizeof(tx));
	wr(SPI_LOOPBACK, saved);
	goodix_trace("goodix: engine loopback %s: sent a5 5a 3c c3, read back %02x %02x %02x %02x (status %#x)\n",
	    ok ? "works" : "FAILS", rx[0], rx[1], rx[2], rx[3], rd(GENI_M_IRQ_STATUS));
}

/* The first register of a run of blocks, eight to a line: a pin array shows itself as a run of small
 * plausible values, and whatever else is at the base shows itself as something else. */
static void
dump_blocks(unsigned first, unsigned count)
{
	char line[512];
	int off = 0;

	off += snprintf(line, sizeof(line), "goodix: blocks %u..%u:", first, first + count - 1);
	for (unsigned i = 0; i < count && off > 0 && (size_t)off < sizeof(line) - 16; i++) {
		off += snprintf(line + off, sizeof(line) - (size_t)off, " %x", rd(tlmm + 0x1000UL * (first + i)));
	}
	loader_log_line(line);
}

/*
 * Where the pins really are. The device tree puts the controller at 0x0f000000 on the star, but every
 * block of that base reads zero, while the clock controller, the serial engine and the RPMh all take
 * writes. The mainline kernel for this SoC puts the same controller at 0x0f100000, exactly 1 MiB
 * higher, and the star's own node is 16 MiB wide -- so the pins may well begin at the 1 MiB mark of a
 * wrapper, and the device tree entry only names the wrapper.
 *
 * This is a read-only probe on purpose: writing to a block that is not a pin has already taken this
 * phone down once, and an answer is worth nothing if the phone does not live to log it. Both bases
 * are read at gpio0 and at gpio22; whichever shows a pin's pattern of small values is the one.
 */
static void
pin_base_probe(void)
{
	static const unsigned pins[] = { 0, 22, 23, 48, 49, 50, 51, 132, 154 };
	char line[512];
	int off = snprintf(line, sizeof(line), "goodix: pin map %#lx, blocks 0..7:", (unsigned long)tlmm);

	for (unsigned k = 0; k < 8; k++) {
		off += snprintf(line + off, sizeof(line) - (size_t)off, " %x", rd(tlmm + 0x1000UL * k));
	}
	loader_log_line(line);
	off = snprintf(line, sizeof(line), "goodix: pin config at this base:");
	for (unsigned i = 0; i < sizeof(pins) / sizeof(pins[0]); i++) {
		off += snprintf(line + off, sizeof(line) - (size_t)off, " gpio%u=%#x",
		    pins[i], rd(tlmm + 0x1000UL * pins[i]));
	}
	loader_log_line(line);
}

static void
diagnose(void)
{
	bool writes_stay;
	unsigned found_block = 99, found_function = 0;

	geni_loopback_probe();
	goodix_trace("goodix: diagnose: the engine answered; now the pin bases\n");
	pin_base_probe();
	goodix_trace("goodix: diagnose: the bases answered\n");

	/*
	 * Does a write to the pin controller stay? gpio154's block is one of the star's touch pins by
	 * every account, and pull-up + input drives nothing, so the board cannot be hurt by it.
	 */
	{
		uint32_t before = rd(tlmm + 0x1000UL * 154), after;

		wr(tlmm + 0x1000UL * 154, 0x00000083);
		sleep_ms(2);                            /* device memory: let the write reach the pins */
		after = rd(tlmm + 0x1000UL * 154);
		goodix_trace("goodix: block 154 reads %#x, and %#x after writing 0x83\n", before, after);
		writes_stay = after == 0x00000083;
	}

	for (unsigned first = 0; first < 32; first += 8) {
		dump_blocks(first, 8);
	}

	if (!writes_stay) {
		goodix_trace("goodix: the pin controller keeps no write: the pins were never configured, which is why "
		    "nothing ever answered\n");
		gpio_block = 0;
		return;
	}
	goodix_trace("goodix: the pin controller keeps a write\n");
	for (unsigned block = 0; block < 2 && found_block == 99; block++) {
		gpio_block = block;
		power_on();
		touch_reset();                          /* once per block: the chip needs a second of it */

		for (unsigned function = 1; function < 12; function++) {
			if (spi_function_given && function != spi_function) {
				continue;               /* touch_spi_func=N said which one to use: no sweep */
			}
			spi_function = function;
			use_engine_pins();
			if (bus_sniff(block, function)) {
				found_block = block;
				found_function = function;
				break;
			}
		}
	}

	if (found_block == 99) {
		goodix_trace("goodix: no pin function brought an answer from the chip\n");
		gpio_block = 0;
		if (!spi_function_given) {
			spi_function = PIN_FUNCTION_SPI;
		}
	} else {
		goodix_trace("goodix: the chip answers with block %u, pin function %u (qup11); keeping both\n",
		    found_block, found_function);
		gpio_block = found_block;
		spi_function = found_function;
	}
	power_on();
	use_engine_pins();
}

static bool
bring_up(void)
{
	const char *problem = "its clocks cannot be turned on";

	/* the two supplies of the chip follow the phone the serial engine belongs to */
	if (site->phys == 0x00a8c000) {
		pin_avdd = PIN_AVDD_STAR;
		pin_vdd = PIN_VDD_STAR;
	} else {
		pin_avdd = PIN_AVDD_REDWOOD;
		pin_vdd = 0;
	}

	show_state("as found");
	touch_chip = touch_chip_detect();
	goodix_trace("goodix: ID gpio96=%u gpio68=%u: the straps suggest %s; the chip that answers decides\n",
	    gpio_get(PIN_GOODIX_ID), gpio_get(PIN_FOCALTECH_ID), chip_name());
	power_on();
	/*
	 * The vendor's fts_chip_powercycle leaves the reset line low for a second after power is up,
	 * then releases it. power_on() only drives it low; without this the chip never leaves reset and
	 * nothing on the bus can answer -- the diagnostic sweep used to hide this by resetting itself.
	 */
	touch_reset();
	show_state("power on, reset released");

	if (clocks_on()) {
		goodix_trace("goodix: serial engine: firmware %#x, interface %#x, parameters %#x, source clock %u Hz (select %u)\n",
		    rd(GENI_FW_REVISION_RO), rd(GENI_IF_DISABLE_RO), rd(SE_HW_PARAM_0), se_source_hz, se_clock_select);
		uint32_t spi_hz = 1000000;

		/* boot-arg touch_spi_hz=N: the bus at N Hz (the Xiaomi 11 Ultra's own driver sets 12 MHz) */
		PE_parse_boot_argn("touch_spi_hz", &spi_hz, sizeof(spi_hz));
		if (spi_hz < 100000 || spi_hz > 20000000) {
			spi_hz = 1000000;
		}
		goodix_trace("goodix: the bus at %u Hz\n", spi_hz);
		problem = geni_spi_init(spi_hz);
	}
	if (problem == NULL) {
		use_engine_pins();
		spi_transfer = geni_transfer;
		show_state("powered, on the serial engine");
		stm_raw_probe();
		{
			/* boot-arg touch_diag=0: the pin base, mux value and write path are known now; skip the
			 * sweep so the chip probe's own log fits in the loader's short USB window. */
			uint32_t diag = 1;

			PE_parse_boot_argn("touch_diag", &diag, sizeof(diag));
			if (diag) {
				diagnose();
			}
		}
		show_state("after the diagnosis");
		if (chip_probe(true)) {
			return true;
		}
		goodix_trace("goodix: %s did not answer through the serial engine; trying the pins by hand\n", chip_name());
	} else {
		goodix_trace("goodix: %s; driving the pins by hand\n", problem);
	}

	/* by hand; which of the two data pins is the input is not written down anywhere, so try both */
	spi_transfer = bitbang_transfer;
	for (int attempt = 0; attempt < 2; attempt++) {
		bitbang_in = attempt == 0 ? PIN_MISO : PIN_MOSI;
		bitbang_out = attempt == 0 ? PIN_MOSI : PIN_MISO;
		bitbang_init();
		if (chip_probe(true)) {
			goodix_trace("goodix: %s answers on pins driven by hand (data in on gpio%u)\n", chip_name(), bitbang_in);
			return true;
		}
	}
	show_state("no answer");
	return false;
}

static uint64_t
micros_now(void)
{
	uint64_t ns;

	absolutetime_to_nanoseconds(mach_absolute_time(), &ns);
	return ns / 1000;
}

static void
goodix_thread(__unused void *parameter, __unused wait_result_t result)
{
	unsigned idle = 0, idle_looks;
	uint32_t poll_us = 4000, latency = 0, reads = 0;
	uint64_t before = 0, reading = 0;

	goodix_trace("goodix: the thread runs\n");
	PE_parse_boot_argn("touch_poll_us", &poll_us, sizeof(poll_us));
	PE_parse_boot_argn("touch_lat", &latency, sizeof(latency));
	if (poll_us < 250 || poll_us > 100000) {
		poll_us = 4000;
	}
	idle_looks = 80000 / poll_us;   /* a report read every 80 ms even with the line high, in case it is missed */

	{
		uint32_t tlmm_phys = TLMM_PHYS_STAR, se_phys = 0, fts_x = 0, fts_y = 0;

		/* boot-arg touch_tlmm=<hex>, touch_se=<hex>: the two bases, when they are not the star's */
		PE_parse_boot_argn("touch_tlmm", &tlmm_phys, sizeof(tlmm_phys));
		if (tlmm_phys == 0) {
			tlmm_phys = TLMM_PHYS_STAR;
		}
		if (PE_parse_boot_argn("touch_se", &se_phys, sizeof(se_phys)) && se_phys) {
			for (unsigned i = 0; i < sizeof(se_sites) / sizeof(se_sites[0]); i++) {
				if (se_sites[i].phys == se_phys) {
					site = &se_sites[i];
					break;
				}
			}
		}
		/* boot-arg fts_max_x=/fts_max_y=: the panel size the reports are measured against */
		if (PE_parse_boot_argn("fts_max_x", &fts_x, sizeof(fts_x)) && fts_x) {
			focaltech_max_x = fts_x;
		}
		if (PE_parse_boot_argn("fts_max_y", &fts_y, sizeof(fts_y)) && fts_y) {
			focaltech_max_y = fts_y;
		}
		/* boot-arg stm_tail=N: where the STM read phase starts, overriding stm_probe() */
		{
			uint32_t tail = 0;

			if (PE_parse_boot_argn("stm_tail", &tail, sizeof(tail)) && tail <= 4) {
				stm_tail = tail;
				stm_tail_forced = true;
			}
		}
		/* boot-arg touch_spi_func=N: the pin controller's number for "qup11", when it is known */
		{
			uint32_t function = 0;

			if (PE_parse_boot_argn("touch_spi_func", &function, sizeof(function)) && function) {
				spi_function = function;
				spi_function_given = true;
			}
		}
		se_cbcr_off = site->cbcr;
		se_cmd_off = site->cmd;
		se_vote_bit = site->vote;

		goodix_trace("goodix: pins at %#x, the serial engine at %#x (%s); panel %u x %u for the reports\n",
		    tlmm_phys, site->phys, site->name, focaltech_max_x, focaltech_max_y);
		tlmm = ml_io_map(tlmm_phys, TLMM_SIZE);
		gcc = ml_io_map(GCC_PHYS, GCC_SIZE);
		se = ml_io_map(site->phys, SE_SIZE);
		if (!tlmm || !gcc || !se) {
			goodix_trace("goodix: a register window would not map: pins %#lx, clocks %#lx, engine %#lx\n",
			    (unsigned long)tlmm, (unsigned long)gcc, (unsigned long)se);
			thread_terminate(current_thread());
			return;
		}
	}
	rsc = ml_io_map(RSC_PHYS, RSC_SIZE);
	cmd_db = ml_io_map_wcomb(CMD_DB_PHYS, CMD_DB_SIZE);      /* memory, not registers: no alignment rules */

	if (!bring_up()) {
		goodix_trace("goodix: no %s touch screen\n", chip_name());
		thread_terminate(current_thread());
		return;
	}
	goodix_trace("goodix: %s touch screen ready; the interrupt line is looked at every %u us\n", chip_name(), poll_us);
	{
		uint32_t rate = 0;

		/* boot-arg touch_rate=480: the chip reports twice as often (Xiaomi's game mode; 240 otherwise) */
		if (PE_parse_boot_argn("touch_rate", &rate, sizeof(rate)) && rate == 480 && touch_chip == TOUCH_GOODIX) {
			bool done = goodix_command(GOODIX_CMD_HIGH_RATE, 1);

			report_rate = done ? "480 (acknowledged)" : "240 (480 NOT ACKNOWLEDGED)";
			goodix_trace("goodix: reports 480 times a second (command %#x at %#x): %s\n", GOODIX_CMD_HIGH_RATE, command_address,
			    done ? "acknowledged" : "NOT ACKNOWLEDGED");
		}
	}
	for (unsigned tick = 1;; tick++) {
		uint64_t looked = micros_now(), read_at;
		bool line_low = !gpio_get(PIN_INT);

		/* the interrupt line is low while a report waits; look anyway every 80 ms in case it is missed */
		if (line_low) {
			idle = 0;
		} else if (++idle >= idle_looks) {
			idle = 0;
			line_low = true;
		}
		if (line_low) {
			unsigned bursts = 0;

			/*
			 * Keep reading while the controller still has queued events. Sleeping between
			 * batches let the queue grow to four or five entries during a drag, and every
			 * extra entry was another 4-8 ms of lag on top of the previous one.
			 */
			for (;;) {
				bool more = chip_poll();

				reads++;
				read_at = micros_now();
				reading += read_at - looked;
				looked = read_at;
				if (!more || ++bursts >= 8 || gpio_get(PIN_INT)) {
					break;
				}
			}
			if (latency) {
				annibale_tl("tl: c before %llu seen %llu read %llu\n", before, looked, read_at);
			}
		}
		before = looked;
		if (tick % (60 * (1000000 / poll_us)) == 0) {
			goodix_trace("%s: so far %u reports in %u looks (%u bad), %u finger positions, the last at %u, %u; "
			    "interrupt line %s; a report takes %llu us to read; the line looked at every %u us, reports %s a second\n",
			    chip_name(), seen.reports, seen.polls, seen.bad, seen.touches, seen.last_x, seen.last_y,
			    gpio_get(PIN_INT) ? "high" : "low", reads ? reading / reads : 0, poll_us, report_rate);
		}
		sleep_us(poll_us);
	}
}

static bool annibale_goodix_inited;   /* iOS26 input.c calls init twice; iOS16 called once */
static void annibale_goodix_probe_now(void);

/* Boot-time init would contend with launchd's preboot/ignition on RPMh and trap the boot.
 * Enter from a thread that waits for userland to come up, then run the real probe. */
static void
annibale_goodix_delayed(void *parameter, wait_result_t result)
{
	(void)parameter; (void)result;
	delay_for_interval(12, NSEC_PER_SEC);
	annibale_goodix_probe_now();
}

static void
annibale_goodix_probe_now(void)
{

	uint32_t enabled = 0;
	thread_t thread;
	kern_return_t started;
	bool parsed;

	loader_log_line("\nGOODIX_INIT_ENTERED\n");     /* straight into the loader's log, whatever printf does */
	goodix_trace("goodix: init entered (touchscreen=%u)\n", enabled);
	parsed = PE_parse_boot_argn("touchscreen", &enabled, sizeof(enabled));
	goodix_trace("goodix: init: touchscreen=%s%u (the boot argument %s read)\n", parsed ? "" : "(absent) ", enabled,
	    parsed ? "was" : "was not");
	if (!parsed || !enabled) {
		goodix_trace("goodix: the touch screen is off (boot-arg touchscreen=1 turns it on)\n");
		return;
	}
	PE_parse_boot_argn("touch_flip", &flip, sizeof(flip));
	started = kernel_thread_start(goodix_thread, NULL, &thread);
	goodix_trace("goodix: the driver's thread: %d\n", (int)started);
	if (started == KERN_SUCCESS) {
		thread_deallocate(thread);
	}
}

void
annibale_goodix_init(void)
{
	uint32_t enabled = 0;
	thread_t thread;

	if (annibale_goodix_inited) return;
	if (!PE_parse_boot_argn("touchscreen", &enabled, sizeof(enabled)) || !enabled) return;
	annibale_goodix_inited = true;
	if (kernel_thread_start(annibale_goodix_delayed, NULL, &thread) == KERN_SUCCESS)
		thread_deallocate(thread);
}
