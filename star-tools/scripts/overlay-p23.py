import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")
lines = [re.sub(r"\s+", " ", l).strip() for l in data.split("\n") if l.strip()]

print("=== BootUI / overlay / PUIProgressWindow ===")
for l in lines:
    if re.search(r"BootUI|Overlay|overlay|PUIProgressWindow|progress", l):
        print("  ", l[:220])

print("\n=== Metal allocate failures ===")
for l in lines:
    if re.search(r"Failed to allocate|framebuffer MTLPixelFormat", l):
        print("  ", l[:220])
