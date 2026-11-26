#!/usr/bin/env python3
"""P34: ask the display driver what it is actually putting on the panel.

P33 proved the panel, the backlight and the scanout are alive: painting fBase red turned the
screen red.  The screen went black after that, which leaves exactly three possibilities, and this
probe separates them in one run:

  * the picture the compositor hands over is black      -> "surface" sample is black
  * the picture is fine but the copy to the panel is not -> "surface" is not black, "panel" is
  * the panel holds a picture but nothing lights it      -> "panel" is not black, screen is black

It also reports the one path in this driver that blanks the panel on purpose: a swap that takes
the bottom layer away.
"""
import sys

SRC = "/root/star26/kbuild/xnu-12377.121.6/iokit/Kernel/MiniIOMobileFramebuffer.cpp"

with open(SRC) as f:
    text = f.read()

if "P34_SAMPLE" in text or "p34_sample" in text:
    print("already patched")
    sys.exit(0)

# 1. the boot argument and the sampler itself, next to fbpaint.
anchor = 'static TUNABLE(uint32_t, gPaint, "fbpaint", 0);\n'
assert anchor in text, "fbpaint tunable not found"
assert text.count(anchor) == 1, "fbpaint tunable is not unique"

sampler = anchor + '''
/* P34_SAMPLE */
static TUNABLE(uint32_t, gProbe, "fbprobe", 0);

/*
 * How much of a picture is not black, on a fixed grid, plus the first four pixels. Coarse on
 * purpose: this runs inside the swap, and it must not cost the frame its own time.
 */
static void
p34_sample(const char * what, uint32_t swapid, const uint8_t * base, uint32_t width, uint32_t height, uint32_t stride)
{
	uint32_t notblack = 0, samples = 0, sums[4] = { 0, 0, 0, 0 };
	uint32_t first[4] = { 0, 0, 0, 0 };
	uint32_t stepx, stepy;

	if (base == NULL || width == 0 || height == 0 || stride == 0) {
		IOLog("P34: %s swap %u: nothing to look at (%p %ux%u %u)\\n", what, swapid, base, width, height, stride);
		return;
	}
	for (unsigned i = 0; i < 4; i++) {
		first[i] = ((const uint32_t *) base)[i];
	}
	stepx = width / 64 + 1;
	stepy = height / 64 + 1;
	for (uint32_t y = 0; y < height; y += stepy) {
		const uint32_t * row = (const uint32_t *) (base + (size_t) y * stride);

		for (uint32_t x = 0; x + 3 < width; x += stepx) {
			uint32_t v = row[x];

			if ((v & 0x00ffffffu) != 0) {
				notblack++;
			}
			sums[0] += v & 0xff;
			sums[1] += (v >> 8) & 0xff;
			sums[2] += (v >> 16) & 0xff;
			samples++;
		}
	}
	IOLog("P34: %s swap %u %ux%u stride %u: %u of %u samples not black, mean b %u g %u r %u, "
	    "first %08x %08x %08x %08x\\n", what, swapid, width, height, stride, notblack, samples,
	    samples ? sums[0] / samples : 0, samples ? sums[1] / samples : 0, samples ? sums[2] / samples : 0,
	    first[0], first[1], first[2], first[3]);
}

'''
text = text.replace(anchor, sampler, 1)

# 2. say so when the panel is blanked because the bottom layer went away.
blank = """			/* the bottom layer taken away: nothing is shown, the screen is black */
			if (layer == 0 && (set & 1) && fGraphics) {"""
assert blank in text, "blanking path not found"
assert text.count(blank) == 1, "blanking path is not unique"
text = text.replace(blank, """			/* the bottom layer taken away: nothing is shown, the screen is black */
			if (layer == 0 && (set & 1) && fGraphics) {
				IOLog("P34: swap %u took the bottom layer away: the panel is blanked on purpose\\n",
				    swapWord(swap, SWAP_ID));""", 1)

# 3. sample the picture the compositor sent, before it is copied.
surf = """		if (s == NULL) {
			continue;
		}
		if (s->info.bytesPerElement == 4 && s->info.planeCount == 0) {"""
assert surf in text, "layer loop body not found"
assert text.count(surf) == 1, "layer loop body is not unique"
text = text.replace(surf, """		if (s == NULL) {
			continue;
		}
		if (layer == 0 && gProbe != 0) {
			p34_sample("surface", swapWord(swap, SWAP_ID), (const uint8_t *) s->pixels(),
			    s->info.width, s->info.height, s->info.bytesPerRow);
		}
		if (s->info.bytesPerElement == 4 && s->info.planeCount == 0) {""", 1)

# 4. and sample the panel once the copy is done.
draw = """			drawLayer(s, src, dst);
			if (layer == 0) {
				recorded = s;   /* (recorded once the frame is in the panel's memory: see below) */"""
assert draw in text, "drawLayer call not found"
assert text.count(draw) == 1, "drawLayer call is not unique"
text = text.replace(draw, """			drawLayer(s, src, dst);
			if (layer == 0) {
				if (gProbe != 0) {
					p34_sample("panel", swapWord(swap, SWAP_ID), fBase,
					    fPanelWidth, fPanelHeight, fRowBytes);
				}
				recorded = s;   /* (recorded once the frame is in the panel's memory: see below) */""", 1)

with open(SRC, "w") as f:
    f.write(text)
print("P34 probe patched into", SRC)
