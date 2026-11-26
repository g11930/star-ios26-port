p = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
s = open(p).read()

# 1) a single helper for the boot arg, used everywhere a measurement gates a step
if "adreno_no_measure(" not in s:
    helper = """/*
 * gpu_nomeasure=1: the frequency counter's debug mux selectors are SoC specific, and on star
 * the ones this driver was written for read the crystal as 0 Hz.  The measurements are
 * sanity checks on the steps, not inputs to them, so on a SoC whose selectors are not known
 * they are declared out of the way rather than guessed at.
 */
static bool
adreno_no_measure(void)
{
	static int on = -1;
	uint32_t v;

	if (on < 0) {
		v = 0;
		on = (PE_parse_boot_argn("gpu_nomeasure", &v, sizeof(v)) && v) ? 1 : 0;
	}
	return on == 1;
}

"""
    anchor = "static bool\nmeasure_clocks(void)\n{"
    assert anchor in s
    s = s.replace(anchor, helper + anchor, 1)

# 2) drop the local static copy in measure_clocks and call the helper
old_local = """	static int no_measure = -1;
	if (no_measure < 0) {
		uint32_t v = 0;
		no_measure = (PE_parse_boot_argn("gpu_nomeasure", &v, sizeof(v)) && v) ? 1 : 0;
	}
	if (no_measure) {"""
new_local = """	if (adreno_no_measure()) {"""
assert old_local in s
s = s.replace(old_local, new_local, 1)

# 3) step 6's ahb check
old_ahb = """	ahb_hz = measure_quietly(GPUCC_DEBUG_AHB);
	if (ahb_hz == MEASURE_FAILED) {
		printf("adreno: %u: the frequency counter did not finish (step 5 shows whether it works)\\n", step);
	} else {
		printf("adreno: %u: the GPU block's register bus clock (ahb) measures %u Hz\\n", step, ahb_hz);
	}
	if (ahb_hz == MEASURE_FAILED || ahb_hz < 1000000) {
		printf("adreno: %u: without that clock a register of the GPU block would not answer: not touching it\\n", step);
		return false;
	}"""
new_ahb = """	if (adreno_no_measure()) {
		printf("adreno: %u: the register bus clock is not measured (gpu_nomeasure=1); the block answered "
		    "gpucc just now, which is what the measurement was standing in for\\n", step);
	} else {
		ahb_hz = measure_quietly(GPUCC_DEBUG_AHB);
		if (ahb_hz == MEASURE_FAILED) {
			printf("adreno: %u: the frequency counter did not finish (step 5 shows whether it works)\\n", step);
		} else {
			printf("adreno: %u: the GPU block's register bus clock (ahb) measures %u Hz\\n", step, ahb_hz);
		}
		if (ahb_hz == MEASURE_FAILED || ahb_hz < 1000000) {
			printf("adreno: %u: without that clock a register of the GPU block would not answer: not touching it\\n",
			    step);
			return false;
		}
	}"""
assert old_ahb in s
s = s.replace(old_ahb, new_ahb, 1)

open(p, "w").write(s)
print("patched ahb gate + helper")
