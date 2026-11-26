import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")

lines = [re.sub(r"\s+", " ", l).strip() for l in data.split("\n")]
alloc = [l for l in lines if re.search(r"rwa (alloc|dealloc)", l)]
print("rwa alloc/dealloc lines:", len(alloc))
for l in alloc[:40]:
    print("  ", l[:200])

print("\n=== out of memory / ENOMEM / vm_page / memory pressure ===")
for l in lines:
    if re.search(r"out of memory|no memory|ENOMEM|memory pressure|jetsam|kmem_alloc.*fail|alloc failed", l, re.I):
        print("  ", l[:200])
