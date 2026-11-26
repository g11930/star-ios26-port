import io, os, shutil, sys

F = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
BAK = F + ".s216-pre"

src = io.open(F, "r", encoding="utf-8", newline="").read()

if not os.path.exists(BAK):
    shutil.copy2(F, BAK)
    print("backup ->", BAK)
else:
    print("backup already exists:", BAK)

def sub(old, new, tag):
    global src
    n = src.count(old)
    if n != 1:
        print("FAIL[%s]: expected 1 occurrence, found %d" % (tag, n))
        sys.exit(1)
    src = src.replace(old, new)
    print("ok[%s]" % tag)

# A. header doc for adreno_speed
sub(
""" *   adreno_speed=N     step 17 asks the GMU for the 3D core's Nth speed: 1 315 MHz, 2 450 MHz,
 *                      3 550 MHz (the default: the most this phone's GPU is rated for)""",
""" *   adreno_speed=N     step 17 asks the GMU for the 3D core's Nth speed. The table is this phone's
 *                      own ten speeds (dt qcom,gpu-pwrlevels of star, "levels" in brackets):
 *                      1 315 (64), 2 379 (80), 3 443 (128), 4 491 (144), 5 540 (192), 6 608 (224),
 *                      7 676 (256), 8 738 (320), 9 778 (384), 10 840 (416) MHz. Default: 10, the
 *                      most this phone's GPU is rated for.""",
"header-adreno-speed")

# B. block comment above step_core_power
sub(
"""/*
 * What the vendor's driver sends at this point (a6xx_hfi_start; Linux the same with fewer
 * levels): the table of speeds of the 3D core with the supply level each needs -- the phone's
 * three lowest (dt: qcom,gpu-pwrlevels: 315, 450, 550 MHz at "levels" 64, 128, 192) -- and of the
 * GMU itself; the table of bus bandwidth votes, of which Linux gets by with the one for "off"
 * (a6xx_hfi.c: adreno_7c3_build_bw_table); "start"; and the speed wanted now. Then the request
 * to keep the 3D core powered while we use it (a6xx_gmu_oob_set), and its registers can be read.
 */""",
"""/*
 * What the vendor's driver sends at this point (a6xx_hfi_start): the table of speeds of the 3D
 * core with the supply level each needs, and of the GMU itself; the table of bus bandwidth votes,
 * of which Linux gets by with the one for "off" (a6xx_hfi.c: a6xx_build_bw_table); "start"; and
 * the speed wanted now. Then the request to keep the 3D core powered while we use it
 * (a6xx_gmu_oob_set), and its registers can be read.
 *
 * The speeds are this phone's own ten (dt: qcom,kgsl-3d0@3d00000/qcom,gpu-pwrlevel-bins, speed
 * bins 0, 5 and 7 alike; the "level" is the qcom,level of the same entry, the RPMh level of the
 * rail gfx.lvl). This driver first carried the three of the 778G it was written on (315, 450 and
 * 550 MHz labelled at levels 64, 128 and 192) -- 450 is not one of this phone's speeds, and 128
 * and 192 are 443 and 540 MHz here, so the core ran one third of its range below its rating.
 */""",
"block-comment")

# C. the table itself
sub(
"""	} speeds[] = { { 0, 0 }, { 315000, 64 }, { 450000, 128 }, { 550000, 192 } };""",
"""	} speeds[] = {
		{ 0, 0 },
		{ 315000, 64 }, { 379000, 80 }, { 443000, 128 }, { 491000, 144 }, { 540000, 192 },
		{ 608000, 224 }, { 676000, 256 }, { 738000, 320 }, { 778000, 384 }, { 840000, 416 },
	};""",
"speeds-table")

# D. default gear
sub(
"""static uint32_t core_khz;               /* the 3D core's speed, as asked of the GMU */""",
"""static uint32_t core_khz;               /* the 3D core's speed, as asked of the GMU */
#define GPU_SPEED_DEFAULT       10      /* index into speeds[]: 840 MHz, the most this phone is rated for */""",
"default-macro")

sub(
"""	uint32_t core_start[2] = { 0, 0 }, start[1] = { 0 }, vote[4] = { 0, 1, 3, HFI_NO_INDEX }, granted = 0, speed = 0;""",
"""	uint32_t core_start[2] = { 0, 0 }, start[1] = { 0 }, vote[4] = { 0, 1, GPU_SPEED_DEFAULT, HFI_NO_INDEX };
	uint32_t granted = 0, speed = 0;""",
"default-index")

# E. votes log: all gears
sub(
"""	printf("adreno: %u: votes: 3D core %#x %#x %#x %#x, GMU %#x %#x\\n", step, perf.gpu[0].vote, perf.gpu[1].vote,
	    perf.gpu[2].vote, perf.gpu[3].vote, perf.gmu[0].vote, perf.gmu[1].vote);""",
"""	printf("adreno: %u: %u speeds, %u..%u MHz; votes:", step, perf.gpu_levels - 1, speeds[1].khz / 1000,
	    speeds[perf.gpu_levels - 1].khz / 1000);
	for (unsigned i = 0; i < perf.gpu_levels; i++) {
		printf(" %u@%#x", speeds[i].khz / 1000, perf.gpu[i].vote);
	}
	printf("; GMU %#x %#x\\n", perf.gmu[0].vote, perf.gmu[1].vote);""",
"votes-log")

# F. the wanted speed log: say which gear it is
sub(
"""	printf("adreno: %u: the speed wanted: %u MHz\\n", step, core_khz / 1000);""",
"""	printf("adreno: %u: the speed wanted: %u MHz (speed %u of %u)\\n", step, core_khz / 1000, vote[2],
	    perf.gpu_levels - 1);""",
"wanted-log")

io.open(F, "w", encoding="utf-8", newline="").write(src)
print("\nPATCH WRITTEN")

# show the result
import subprocess
print(subprocess.run(["sed", "-n", "2318,2380p", F], capture_output=True, text=True).stdout)
