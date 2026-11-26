import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p26-staged.bin"
data = open(path, "rb").read()

end = data.find(b"== END OF LOG ==")
live = data[:end] if end > 0 else data
print("file %d bytes, live region %d bytes (ends at %d)" % (len(data), len(live), end))
txt = live.replace(b"\x00", b"\n").decode("latin-1")

keys = [
    "render pipeline is refused",
    "half lowering does not support",
    "does not support tex op",
    "failed to build render pipeline",
    "Mesa would not allocate",
    "client-memory copy allocation failed",
    "null_sw_displaytarget_create",
    "Failed to allocate [",
    "no drawable",
    "no connection to AnnibaleGPU",
    "Failed to initialize Metal or OpenGLES contexts",
    "registration completed",
    "first_frame at",
    "MiniIOMobileFramebuffer: swap",
    "pendingCheckIn: YES",
    "panic",
    "initproc failed",
]
print("\n=== counts ===")
for k in keys:
    print("  %-52s %d" % (k, txt.count(k)))


def show(tag, pat, limit=6, before=40, after=260):
    hits = list(re.finditer(pat, txt))
    print("\n=== %s : %d ===" % (tag, len(hits)))
    for m in hits[:limit]:
        s = txt[max(0, m.start() - before): m.start() + after]
        print("   ", re.sub(r"\s+", " ", s).strip()[:320])


show("pipeline refused", r"pipeline[^\n]{0,20}refused[^\n]*", limit=8)
show("spec that failed", r"failed to build render pipeline[^\n]*", limit=6)
show("no drawable", r"no drawable[^\n]*", limit=4)
show("buffer allocations", r"rwa buffer: [^\n]*", limit=5)
show("first frame", r"milestone: first_frame[^\n]*", limit=3)

swaps = list(re.finditer(r"MiniIOMobileFramebuffer: swap (\d+) layer", txt))
print("\n=== swaps: %d ===" % len(swaps))
for m in swaps[-8:]:
    s = txt[max(0, m.start() - 90): m.start() + 170]
    print("   ", re.sub(r"\s+", " ", s).strip()[:270])

boot = list(re.finditer(r"bootUI is [^\n]*", txt))
print("\n=== bootUI: %d ===" % len(boot))
for m in boot[:10]:
    print("   ", re.sub(r"\s+", " ", m.group(0)).strip()[:90])

print("\n=== last 16 lines of the live region ===")
for l in [x.strip() for x in txt.split("\n") if x.strip()][-16:]:
    print("   ", re.sub(r"\s+", " ", l)[:200])
