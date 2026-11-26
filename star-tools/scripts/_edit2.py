#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""s218 edit 2: add load/thermal GPU clock tick, temperature reader, speed-state strong symbol;
   edit 3: call the tick from annibale_gpu_submit. One transaction."""
F = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
src = open(F, "r").read()

# ---- insert the new functions just before the submit comment block ----
anchor = """/*
 * Command buffers for the 3D core to run, in order: each an address and a count of words. As
 * Linux's a6xx_submit puts them in the ring. Returns the submission's number; 0: the ring is
 * full and the core is not reading it.
 */
uint32_t
annibale_gpu_submit"""
assert src.count(anchor) == 1, "submit anchor not unique: %d" % src.count(anchor)

new = r'''/* ---- s218: load/thermal-driven GPU clock (after K90's adreno8_speed_tick) ---------------------- */

/*
 * AnnibaleGPU's five-second report asks for the speed last voted and how often it changed. The
 * definition in StarDisplayCompat.cpp is a weak C stub; this strong definition overrides it.
 */
void
annibale_gpu_speed(uint32_t *mhz, uint32_t *changes)
{
	if (mhz != NULL) {
		*mhz = star_speed_now < STAR_GPU_SPEEDS ? star_gpu_speeds[star_speed_now].khz / 1000 : 0;
	}
	if (changes != NULL) {
		*changes = star_speed_changes;
	}
}

/*
 * The hottest GPU sensor in tenths of a degree. The tsens block is already mapped by the minute
 * reader; sensors 1 and 2 sit at the GPU. A sensor caught between readings is retried. No valid
 * reading at all means no answer.
 */
bool
annibale_gpu_temperature(int32_t *tenths)
{
	int32_t hot = -2730;

	if (!gpu_kept || tenths == NULL) {
		return false;
	}
	need(&tsens);
	for (unsigned i = 0; i < 2; i++) {
		for (unsigned again = 0; again < 16; again++) {
			uint32_t status = rd(tsens.base + TSENS_STATUS(1 + i));

			if (status & TSENS_VALID) {
				int32_t t = (int32_t)(status << 20) >> 20;

				if (t > hot) {
					hot = t;
				}
				break;
			}
		}
	}
	if (hot == -2730) {
		return false;
	}
	*tenths = hot;
	return true;
}

/*
 * Choose the core's speed from the work retired since the last tick, its heat, and recent touch.
 * Called with each submission under AnnibaleGPU's lock; acts at most every 100 ms. Adapted from
 * K90's adreno8_speed_tick. There is no touch-time source here (the cpufreq touch stub reads 0),
 * so the touch boost is left out; and a temperature that cannot be read leaves the ceiling as it
 * was instead of forcing the slowest speed, so that load scaling still works without a sensor.
 *
 * A vote the GMU does not acknowledge ends the changes for the run.
 */
#define SPEED_TICK_NS           100000000ull
#define SPEED_UP_PERMILLE       200
#define SPEED_TARGET_PERMILLE   350
#define SPEED_DOWN_PERMILLE     100
#define SPEED_DOWN_NS           500000000ull
#define SPEED_HOT_TENTHS        700
#define SPEED_COOL_TENTHS       600
#define SPEED_CUT_TENTHS        750
#define SPEED_RISE_TICKS        2

static void
star_gpu_speed_tick(void)
{
	uint64_t now = mach_absolute_time(), since, light, permille, busy_ns;
	uint32_t want = star_speed_now, msg[4], floor, step_floor, load_want;
	int32_t tenths = 0;
	bool warm;

	if (star_speed_asked <= 1 || star_speed_asked >= STAR_GPU_SPEEDS) {
		return;
	}
	absolutetime_to_nanoseconds(now - star_speed_ticked, &since);
	if (star_speed_ticked != 0 && since < SPEED_TICK_NS) {
		return;
	}
	/* gpu_ticks holds 19.2 MHz ticks; annibale_gpu_worked() zeroes it, so a wrap restarts the baseline. */
	if (gpu_ticks < star_speed_busy_seen) {
		star_speed_busy_seen = 0;
	}
	busy_ns = (gpu_ticks - star_speed_busy_seen) * 10000 / 192;
	permille = star_speed_ticked != 0 && since != 0 ?
	    busy_ns * 1000 / since * star_gpu_speeds[star_speed_now].khz / star_gpu_speeds[1].khz : 0;
	star_speed_ticked = now;
	star_speed_busy_seen = gpu_ticks;

	if (star_speed_limit == 0) {
		star_speed_limit = star_speed_asked;
	}
	warm = annibale_gpu_temperature(&tenths);
	if (warm && tenths >= SPEED_CUT_TENTHS) {
		star_speed_limit = 1;
		star_speed_cool_ticks = 0;
	} else if (warm && tenths >= SPEED_HOT_TENTHS) {
		star_speed_limit -= star_speed_limit > 1;
		star_speed_cool_ticks = 0;
	} else if (warm && tenths < SPEED_COOL_TENTHS && star_speed_limit < star_speed_asked &&
	    ++star_speed_cool_ticks >= SPEED_RISE_TICKS) {
		star_speed_limit++;
		star_speed_cool_ticks = 0;
	}
	floor = star_speed_floor < 1 ? 1 : (star_speed_floor > star_speed_asked ? star_speed_asked : star_speed_floor);
	step_floor = floor < 3u ? 3u : (floor > star_speed_asked ? star_speed_asked : floor);
	if (permille >= SPEED_UP_PERMILLE) {
		load_want = step_floor;
		while (load_want < star_speed_asked &&
		    (uint64_t)star_gpu_speeds[load_want].khz * SPEED_TARGET_PERMILLE < permille * star_gpu_speeds[1].khz) {
			load_want++;
		}
	} else if (permille < SPEED_DOWN_PERMILLE) {
		load_want = floor;
	} else {
		load_want = star_speed_now < step_floor ? star_speed_now : step_floor;
	}
	if (load_want > star_speed_now) {
		want = load_want;
		star_speed_light_since = 0;
	} else if (load_want < star_speed_now) {
		if (star_speed_light_since == 0) {
			star_speed_light_since = now;
		}
		absolutetime_to_nanoseconds(now - star_speed_light_since, &light);
		if (light >= SPEED_DOWN_NS) {
			want = load_want;
			star_speed_light_since = 0;
		}
	} else {
		star_speed_light_since = 0;
	}
	want = want < floor ? floor : (want > star_speed_limit ? star_speed_limit : want);
	if (want == star_speed_now) {
		return;
	}
	/* HFI changes the GX clock, voltage and DDR bandwidth; the four-word vote is the one already used. */
	msg[0] = 0;
	msg[1] = 1;
	msg[2] = want;
	msg[3] = HFI_NO_INDEX;
	if (!hfi_send("the GPU's speed", HFI_GX_BW_PERF_VOTE, msg, 4)) {
		printf("adreno: the GPU speed vote for %u MHz was not acknowledged; staying at %u MHz\n",
		    star_gpu_speeds[want].khz / 1000, star_gpu_speeds[star_speed_now].khz / 1000);
		star_speed_asked = 1;
		return;
	}
	star_speed_now = want;
	star_speed_changes++;
	core_khz = star_gpu_speeds[want].khz;
	printf("adreno: the GPU's speed is now %u MHz (speed %u of %u), %llu permille load%s\n",
	    core_khz / 1000, want, STAR_GPU_SPEEDS - 1, permille, warm ? "" : " [no temperature reading]");
}

'''
src = src.replace(anchor, new + anchor, 1)

# ---- edit 3: call tick in submit, right after gpu_times() ----
call_anchor = """	gpu_times();
	if (++gpu_fence == 0) {
		gpu_fence = 1;
	}"""
assert src.count(call_anchor) == 1, "submit call anchor not unique: %d" % src.count(call_anchor)
src = src.replace(call_anchor, """	gpu_times();
	star_gpu_speed_tick();
	if (++gpu_fence == 0) {
		gpu_fence = 1;
	}""", 1)

open(F, "w").write(src)
print("edit 2 + 3 done")
