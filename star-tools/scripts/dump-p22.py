import re, sys

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()
start = int(sys.argv[1]) if len(sys.argv) > 1 else 170000
end = int(sys.argv[2]) if len(sys.argv) > 2 else 451518
kw = sys.argv[3] if len(sys.argv) > 3 else None

chunk = data[start:end].replace(b"\x00", b"\n").decode("latin-1")
lines = []
for line in chunk.split("\n"):
    line = "".join(ch if 32 <= ord(ch) < 127 else " " for ch in line).strip()
    if not line:
        continue
    if kw and not re.search(kw, line, re.I):
        continue
    lines.append(line)
print("lines:", len(lines))
print("\n".join(lines[:400]))
