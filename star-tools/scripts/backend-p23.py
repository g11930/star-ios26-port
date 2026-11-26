import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")

for pat in ("softpipe", "RWA_SOFTWARE", "backend", "rwa device", "screen", "msm", "a660", "Adreno"):
    hits = [re.sub(r"\s+", " ", data[max(0, m.start() - 120): m.start() + 180]).strip()
            for m in re.finditer(pat, data)]
    print("\n=== %s : %d ===" % (pat, len(hits)))
    for h in hits[:6]:
        print("   ", h[:280])
