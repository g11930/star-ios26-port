import os, struct, tarfile, sys

TAR = "/mnt/d/桌面/star26-deps/gpu-facts/kgsl-dt.tar"
OUT = "/mnt/d/桌面/star26-deps/gpu-facts/dt"
os.makedirs(OUT, exist_ok=True)
if not os.path.isdir(os.path.join(OUT, "qcom,kgsl-3d0@3d00000")):
    tarfile.open(TAR).extractall(OUT)

ROOT = os.path.join(OUT, "qcom,kgsl-3d0@3d00000")
BINS = os.path.join(ROOT, "qcom,gpu-pwrlevel-bins")

def cells(path):
    """FDT cells are big-endian u32."""
    with open(path, "rb") as f:
        d = f.read()
    n = len(d) // 4
    return list(struct.unpack(">%dI" % n, d[:n * 4]))

def s32(v):
    return v - (1 << 32) if v >= (1 << 31) else v

def sval(name):
    p = os.path.join(ROOT, name)
    if not os.path.exists(p):
        return None
    c = cells(p)
    return c[0] if c else None

print("=== node: qcom,kgsl-3d0@3d00000 ===")
print("chipid        : 0x%08x" % (sval("qcom,chipid") or 0))
print("ubwc-mode     :", sval("qcom,ubwc-mode"))
print("highest-bank  :", sval("qcom,highest-bank-bit"))
print("min-access-len:", sval("qcom,min-access-length"))
print("no-nap        :", sval("qcom,no-nap"))

for t in ("qcom,bus-table-ddr7", "qcom,bus-table-ddr8", "qcom,bus-table-cnoc"):
    p = os.path.join(ROOT, t)
    if os.path.isfile(p):
        c = cells(p)
        print("\n%s (%d cells):" % (t, len(c)))
        for i in range(0, len(c), 8):
            print("  ", " ".join("%d" % x for x in c[i:i + 8]))

# interconnect names
p = os.path.join(ROOT, "interconnect-names")
if os.path.exists(p):
    print("\ninterconnect-names:", open(p, "rb").read().split(b"\0"))

print("\n=== pwrlevel bins ===")
for binname in sorted(os.listdir(BINS)):
    bdir = os.path.join(BINS, binname)
    if not os.path.isdir(bdir) or "pwrlevels-" not in binname:
        continue
    sb = None
    p = os.path.join(bdir, "qcom,speed-bin")
    if os.path.exists(p):
        sb = cells(p)[0]
    ini = None
    p = os.path.join(bdir, "qcom,initial-pwrlevel")
    if os.path.exists(p):
        ini = cells(p)[0]
    levels = sorted([d for d in os.listdir(bdir) if d.startswith("qcom,gpu-pwrlevel@")],
                    key=lambda s: int(s.split("@")[1]))
    print("\n--- %s  speed-bin=%s initial-pwrlevel=%s levels=%d" % (binname, sb, ini, len(levels)))
    print("   %-4s %-11s %-6s %-10s %-10s %-10s %-10s %-8s" % (
        "idx", "freq(Hz)", "MHz", "gfx.lvl", "bus-freq8", "bus-max8", "bus-min8", "acd"))
    for lv in levels:
        idx = int(lv.split("@")[1])
        d = os.path.join(bdir, lv)
        def c1(name):
            p = os.path.join(d, name)
            return cells(p)[0] if os.path.exists(p) else None
        f = c1("qcom,gpu-freq")
        lvl = c1("qcom,level")
        print("   %-4d %-11s %-6s %-10s %-10s %-10s %-10s %-8s" % (
            idx, f, ("%d" % (f // 1000000)) if f else "?", lvl,
            c1("qcom,bus-freq-ddr8"), c1("qcom,bus-max-ddr8"), c1("qcom,bus-min-ddr8"),
            c1("qcom,acd-level")))
