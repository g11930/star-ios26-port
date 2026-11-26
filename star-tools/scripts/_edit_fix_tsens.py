#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Move tsens block definition before the s218 speed functions (fix compile: use-before-declare)."""
F = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
src = open(F, "r").read()

# The original definition (with its leading 10-line comment block) near the minute reader.
orig = """/* ---- beside the steps: how warm the GPU is ------------------------------------------------------------------ */

/*
 * The SoC's temperature sensors report by themselves, in a block that is always on (dt: tsens1,
 * whose readings are at 0xc265000; Linux's tsens-v2.c): a status word a sensor, the last reading
 * in its low 12 bits, signed, in tenths of a degree, and bit 21 when there is one. Sensors 1 and
 * 2 sit at the GPU (dt: gpuss-0, gpuss-1). Read, never written: once a minute while the GPU is
 * kept, for the line beside the kernel's line about memory (osfmk/arm64/loader_return.c). A
 * sensor caught between two readings has none for a moment and is asked again; one that still
 * has none is put down as -273.0.
 */
static struct block tsens = { "tsens1", 0x0c265000, 0x200 };
#define TSENS_STATUS(sensor)    (0xa0 + 4 * (sensor))
#define TSENS_VALID             (1u << 21)
"""
assert src.count(orig) == 1, "original tsens block not unique: %d" % src.count(orig)

# Remove it from the original location, leave a short forward note.
replacement = """/* ---- beside the steps: how warm the GPU is ------------------------------------------------------------------ */

/* The tsens sensor block and its TSENS_* macros are defined above, before the speed reader. */
"""
src = src.replace(orig, replacement, 1)

# Insert the definition right before the s218 section (before the speed functions that use it).
anchor = "/* ---- s218: load/thermal-driven GPU clock (after K90's adreno8_speed_tick) ---------------------- */\n"
assert src.count(anchor) == 1, "s218 anchor not unique: %d" % src.count(anchor)
src = src.replace(anchor, orig + "\n" + anchor, 1)

open(F, "w").write(src)
print("tsens moved")
