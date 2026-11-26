p = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
s = open(p).read()

old = """	uint32_t hz, ahb_hz = MEASURE_FAILED;

	announce("measure the GPU block's clocks with the SoC's frequency counter (debug registers at gcc 0x162000.., "
	    "gpucc 0x3d910fc, 0x3d91100, 0x3d91568)");
	hz = measure(GPUCC_DEBUG_CXO);"""

new = """	uint32_t hz, ahb_hz = MEASURE_FAILED;

	/*
	 * gpu_nomeasure=1: the frequency counter's debug mux selectors are SoC specific, and on star
	 * the ones below read the crystal as 0 Hz.  The measurement is a sanity check on step 1 to 5,
	 * not an input to any later step, so it can be declared out of the way here rather than
	 * guessed at: nothing after this point believes a number that came from it.
	 */
	static int no_measure = -1;
	if (no_measure < 0) {
		uint32_t v = 0;
		no_measure = (PE_parse_boot_argn("gpu_nomeasure", &v, sizeof(v)) && v) ? 1 : 0;
	}
	if (no_measure) {
		printf("adreno: %u: measurement skipped (gpu_nomeasure=1); the debug mux selectors are not this SoC's\\n",
		    step);
		return true;
	}

	announce("measure the GPU block's clocks with the SoC's frequency counter (debug registers at gcc 0x162000.., "
	    "gpucc 0x3d910fc, 0x3d91100, 0x3d91568)");
	hz = measure(GPUCC_DEBUG_CXO);"""

assert old in s, "pattern not found"
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("patched measure_clocks")
