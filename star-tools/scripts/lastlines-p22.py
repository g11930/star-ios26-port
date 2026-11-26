import re

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()[:451518].replace(b"\x00", b"\n").decode("latin-1")

for tag in ("backboardd[", "WindowServer", "SpringBoard["):
    lines = [l.strip() for l in data.split("\n") if tag in l]
    print("\n=== %s : %d line(s) ===" % (tag, len(lines)))
    for l in lines[-18:]:
        print("  ", re.sub(r"\s+", " ", l)[:200])
