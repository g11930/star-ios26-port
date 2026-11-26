import re, sys, os

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-logdump.bin"
data = open(path, "rb").read()

end = data.find(b"== END OF LOG ==")
live = data[:end] if end > 0 else data
print("file %d bytes, live region %d bytes (ends at %d)" % (len(data), len(live), end))
txt = live.replace(b"\x00", b"\n").decode("latin-1")

keys = [
    "stub service registered",
    "no drawable",
    "no connection to AnnibaleGPU",
    "client-memory copy allocation failed",
    "registration failed",
    "registration completed",
    "Failed to initialize Metal or OpenGLES contexts",
    "StartWindowServer",
    "first_frame at",
    "MiniIOMobileFramebuffer: swap",
    "panic",
    "initproc failed",
]
print("\n=== counts ===")
for k in keys:
    print("  %-52s %d" % (k, txt.count(k)))


def show(tag, pat, limit=8, before=60, after=230):
    hits = list(re.finditer(pat, txt))
    print("\n=== %s : %d ===" % (tag, len(hits)))
    for m in hits[:limit]:
        s = txt[max(0, m.start() - before): m.start() + after]
        print("   ", re.sub(r"\s+", " ", s).strip()[:280])


show("sbmetal26 registration", r"sbmetal26: registration[^\n]*")
show("no drawable", r"no drawable[^\n]*", limit=4)
show("Metal init failure", r"Failed to initialize Metal[^\n]*", limit=3)
show("window server start", r"StartWindowServer:[^\n]*", limit=4)
show("first frame", r"milestone: first_frame[^\n]*", limit=3)

swaps = list(re.finditer(r"MiniIOMobileFramebuffer: swap (\d+) layer", txt))
print("\n=== swaps: %d ===" % len(swaps))
for m in swaps[-6:]:
    s = txt[max(0, m.start() - 100): m.start() + 200]
    print("   ", re.sub(r"\s+", " ", s).strip()[:300])

print("\n=== last 12 lines of the live region ===")
for l in [x.strip() for x in txt.split("\n") if x.strip()][-12:]:
    print("   ", re.sub(r"\s+", " ", l)[:200])
