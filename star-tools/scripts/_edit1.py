#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""s218 edit 1: promote speeds[] to file-level static + add speed-state globals."""
import re

F = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
src = open(F, "r").read()

# --- 1. Add file-level speeds table + speed state globals after GPU_SPEED_DEFAULT define ---
anchor = "#define GPU_SPEED_DEFAULT       10      /* index into speeds[]: 840 MHz, the most this phone is rated for */\n"
assert src.count(anchor) == 1, "anchor GPU_SPEED_DEFAULT not unique: %d" % src.count(anchor)

new_globals = anchor + """
/*
 * The 3D core's speeds, the same ten the vendor's driver reports (dt: qcom,kgsl-3d0@3d00000/
 * qcom,gpu-pwrlevel-bins, speed bins 0, 5 and 7 alike). Index 0 is a placeholder {0,0}; 1..10
 * are the real ones. The "level" is the qcom,level of the entry, the RPMh level of the rail
 * gfx.lvl.
 */
static const struct {
	uint32_t khz, level;
} star_gpu_speeds[] = {
	{ 0, 0 },
	{ 315000, 64 }, { 379000, 80 }, { 443000, 128 }, { 491000, 144 }, { 540000, 192 },
	{ 608000, 224 }, { 676000, 256 }, { 738000, 320 }, { 778000, 384 }, { 840000, 416 },
};
#define STAR_GPU_SPEEDS        ((uint32_t)(sizeof(star_gpu_speeds) / sizeof(star_gpu_speeds[0])))
/* what the speed wants to be now, the floor and the ceiling the load and the heat set */
static uint32_t star_speed_now = GPU_SPEED_DEFAULT, star_speed_floor = 1, star_speed_limit;
static uint32_t star_speed_changes, star_speed_cool_ticks;
static uint64_t star_speed_ticked, star_speed_busy_seen, star_speed_light_since;
/* the speed asked at step 17 (the top the load may reach); boot-arg adreno_touch_ms=N */
static uint32_t star_speed_asked, star_touch_ms = 300;
"""
src = src.replace(anchor, new_globals, 1)

# --- 2. Remove the local static speeds[] from step_core_power ---
old_local = """	static const struct {
		uint32_t khz, level;
	} speeds[] = {
		{ 0, 0 },
		{ 315000, 64 }, { 379000, 80 }, { 443000, 128 }, { 491000, 144 }, { 540000, 192 },
		{ 608000, 224 }, { 676000, 256 }, { 738000, 320 }, { 778000, 384 }, { 840000, 416 },
	};
"""
assert src.count(old_local) == 1, "local speeds[] not found: %d" % src.count(old_local)
src = src.replace(old_local, "", 1)

# --- 3. Inside step_core_power, use star_gpu_speeds ---
old_fn = """	perf.gpu_levels = sizeof(speeds) / sizeof(speeds[0]);
	for (unsigned i = 0; i < perf.gpu_levels; i++) {
		perf.gpu[i].khz = speeds[i].khz;
		perf.gpu[i].acd = 0xffffffff;           /* no adaptive clocking */
		if (!rail_vote(speeds[i].level, gfx, gfx_levels, mx, mx_levels, &perf.gpu[i].vote)) {"""
new_fn = """	perf.gpu_levels = STAR_GPU_SPEEDS;
	for (unsigned i = 0; i < perf.gpu_levels; i++) {
		perf.gpu[i].khz = star_gpu_speeds[i].khz;
		perf.gpu[i].acd = 0xffffffff;           /* no adaptive clocking */
		if (!rail_vote(star_gpu_speeds[i].level, gfx, gfx_levels, mx, mx_levels, &perf.gpu[i].vote)) {"""
assert src.count(old_fn) == 1, "perf table build not found: %d" % src.count(old_fn)
src = src.replace(old_fn, new_fn, 1)

old_p = '	printf("adreno: %u: %u speeds, %u..%u MHz; votes:", step, perf.gpu_levels - 1, speeds[1].khz / 1000,\n	    speeds[perf.gpu_levels - 1].khz / 1000);\n	for (unsigned i = 0; i < perf.gpu_levels; i++) {\n		printf(" %u@%#x", speeds[i].khz / 1000, perf.gpu[i].vote);'
new_p = '	printf("adreno: %u: %u speeds, %u..%u MHz; votes:", step, perf.gpu_levels - 1, star_gpu_speeds[1].khz / 1000,\n	    star_gpu_speeds[perf.gpu_levels - 1].khz / 1000);\n	for (unsigned i = 0; i < perf.gpu_levels; i++) {\n		printf(" %u@%#x", star_gpu_speeds[i].khz / 1000, perf.gpu[i].vote);'
assert src.count(old_p) == 1, "speeds printf not found: %d" % src.count(old_p)
src = src.replace(old_p, new_p, 1)

# --- 4. speed selection: record star_speed_asked/now/limit ---
old_sel = """	if (PE_parse_boot_argn("adreno_speed", &speed, sizeof(speed)) && speed >= 1 && speed < perf.gpu_levels) {
		vote[2] = speed;
	}
	core_khz = speeds[vote[2]].khz;
	printf("adreno: %u: the speed wanted: %u MHz (speed %u of %u)\\n", step, core_khz / 1000, vote[2],
	    perf.gpu_levels - 1);"""
new_sel = """	if (PE_parse_boot_argn("adreno_speed", &speed, sizeof(speed)) && speed >= 1 && speed < perf.gpu_levels) {
		vote[2] = speed;
	}
	core_khz = star_gpu_speeds[vote[2]].khz;
	star_speed_asked = vote[2];
	star_speed_now = vote[2];
	star_speed_limit = vote[2];
	if (PE_parse_boot_argn("adreno_speed_floor", &star_speed_floor, sizeof(star_speed_floor)) &&
	    star_speed_floor < 1) {
		star_speed_floor = 1;
	}
	if (PE_parse_boot_argn("adreno_touch_ms", &star_touch_ms, sizeof(star_touch_ms))) {
	}
	printf("adreno: %u: the speed wanted: %u MHz (speed %u of %u)\\n", step, core_khz / 1000, vote[2],
	    perf.gpu_levels - 1);"""
assert src.count(old_sel) == 1, "speed selection not found: %d" % src.count(old_sel)
src = src.replace(old_sel, new_sel, 1)

open(F, "w").write(src)
print("edit 1 done")
