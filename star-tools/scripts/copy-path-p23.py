import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")
lines = [re.sub(r"\s+", " ", l).strip() for l in data.split("\n") if l.strip()]

print("=== annibaledrawable import / copy lines ===")
n = 0
for l in lines:
    if re.search(r"annibaledrawable:", l):
        print("  ", l[:230])
        n += 1
        if n > 25:
            break
print("total annibaledrawable lines:", sum(1 for l in lines if "annibaledrawable:" in l))

print("\n=== 'texture' / 'alias' / 'rw_surface' mentions ===")
n = 0
for l in lines:
    if re.search(r"rw_surface|texture alias|alias", l):
        print("  ", l[:230])
        n += 1
        if n > 15:
            break
