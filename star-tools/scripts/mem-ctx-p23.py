import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")
lines = [re.sub(r"\s+", " ", l).strip() for l in data.split("\n") if l.strip()]

print("=== memory related ===")
for l in lines:
    if re.search(r"memorystatus|jetsam|memory limit|max_mem|physical|mem_size|memorysize|avail", l, re.I):
        print("  ", l[:220])

print("\n=== rwa alloc / buffer create nearby ===")
for i, l in enumerate(lines):
    if "would not allocate" in l or "null_sw_displaytarget" in l:
        print("  [%d] %s" % (i, l[:230]))
        print("      prev: %s" % (lines[i-1][:200] if i else ""))
