#!/usr/bin/env python3
"""P33: paint the panel memory a solid colour at start (boot-arg fbpaint=1 red).

One experiment, one question: after the kernel took the display over, is the panel, its backlight
and the controller's scan-out still alive?  A colour that needs no frame drawn answers it, and
whether the frames reach the same memory the controller reads.
"""
import sys

FILES = [
    "/root/star26/kbuild/xnu-12377.121.6/iokit/Kernel/MiniIOMobileFramebuffer.cpp",
    "/root/star26/hackios-xnu-kernel/xnu/files/iokit/Kernel/MiniIOMobileFramebuffer.cpp",
]

TUNABLE_ANCHOR = 'static TUNABLE(uint32_t, gDiff, "fb_diff", 0);\n'
TUNABLE_ADD = TUNABLE_ANCHOR + '''
/* boot-arg fbpaint=N: paint the whole panel memory at start (1 red, 2 green, 3 blue, 4 white).
 * It needs no frame drawn, so it says whether the panel, its backlight and the display
 * controller's scan-out are still alive after the kernel has taken over -- and whether a frame
 * the presenter draws lands in the memory the controller reads.
 */
static TUNABLE(uint32_t, gPaint, "fbpaint", 0);
'''

PAINT_ANCHOR = ('\tIOLog("MiniIOMobileFramebuffer: display %ux%u on a panel of %ux%u (%u bytes per row)\\n", fWidth, fHeight,\n')
PAINT_ADD = '''\tif (gPaint != 0) {
\t\tuint32_t colour = gPaint == 1 ? 0xffff0000u : gPaint == 2 ? 0xff00ff00u : gPaint == 3 ? 0xff0000ffu : 0xffffffffu;

\t\tfor (uint32_t y = 0; y < fPanelHeight; y++) {
\t\t\tuint32_t * row = (uint32_t *) (fBase + (size_t) y * fRowBytes);

\t\t\tfor (uint32_t x = 0; x < fPanelWidth; x++) {
\t\t\t\trow[x] = colour;
\t\t\t}
\t\t}
\t\tIOLog("MiniIOMobileFramebuffer: painted the panel memory %#x (%ux%u, %u bytes a row) at %#llx\\n",
\t\t    colour, fPanelWidth, fPanelHeight, fRowBytes, (unsigned long long) vinfo.v_physaddr);
\t}
''' + PAINT_ANCHOR

for path in FILES:
    with open(path) as f:
        text = f.read()
    if 'fbpaint' in text:
        print("already patched:", path)
        continue
    if TUNABLE_ANCHOR not in text or PAINT_ANCHOR not in text:
        print("ANCHOR MISSING in", path)
        sys.exit(1)
    text = text.replace(TUNABLE_ANCHOR, TUNABLE_ADD, 1)
    text = text.replace(PAINT_ANCHOR, PAINT_ADD, 1)
    with open(path, "w") as f:
        f.write(text)
    print("patched:", path)

print("done")
