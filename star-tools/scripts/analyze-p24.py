import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p24-staged.bin"
data = open(path, "rb").read()

end = data.find(b"== END OF LOG ==")
live = data[:end] if end > 0 else data
print("file %d bytes, live region %d bytes (ends at %d)" % (len(data), len(live), end))
txt = live.replace(b"\x00", b"\n").decode("latin-1")

keys = [
    "Mesa would not allocate",
    "client-memory copy allocation failed",
    "null_sw_displaytarget_create",
    "is sampled through a copy",
    "rwa buffer:",
    "rwa alias:",
    "no drawable",
    "no connection to AnnibaleGPU",
    "Failed to initialize Metal or OpenGLES contexts",
    "Failed to allocate",
    "registration completed",
    "registration failed",
    "first_frame at",
    "MiniIOMobileFramebuffer: swap",
    "panic",
    "initproc failed",
]
print("\n=== counts ===")
for k in keys:
    print("  %-52s %d" % (k, txt.count(k)))


def show(tag, pat, limit=6, before=40, after=240):
    hits = list(re.finditer(pat, txt))
    print("\n=== %s : %d ===" % (tag, len(hits)))
    for m in hits[:limit]:
        s = txt[max(0, m.start() - before): m.start() + after]
        print("   ", re.sub(r"\s+", " ", s).strip()[:300])


show("buffer created (took/copied)", r"rwa buffer: [^\n]*", limit=8)
show("texture over buffer alias", r"rwa alias: [^\n]*", limit=6)
show("sampled through a copy", r"surface 0x[0-9a-f]+ of [^\n]*", limit=6)
show("framebuffer allocation", r"Failed to allocate [^\n]*", limit=4)
show("no drawable", r"no drawable[^\n]*", limit=3)
show("first frame", r"milestone: first_frame[^\n]*", limit=3)

swaps = list(re.finditer(r"MiniIOMobileFramebuffer: swap (\d+) layer", txt))
print("\n=== swaps: %d ===" % len(swaps))
for m in swaps[-8:]:
    s = txt[max(0, m.start() - 90): m.start() + 160]
    print("   ", re.sub(r"\s+", " ", s).strip()[:260])

print("\n=== last 14 lines of the live region ===")
for l in [x.strip() for x in txt.split("\n") if x.strip()][-14:]:
    print("   ", re.sub(r"\s+", " ", l)[:200])
