import re

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()[:451518].replace(b"\x00", b"\n").decode("latin-1")

print("=== Metal / rwa / annibalemetal lines ===")
seen = 0
for l in data.split("\n"):
    l = re.sub(r"\s+", " ", l).strip()
    if re.search(r"metal|rwa|softpipe|IOSurface|drawable", l, re.I):
        print("  ", l[:210])
        seen += 1
        if seen > 45:
            break
