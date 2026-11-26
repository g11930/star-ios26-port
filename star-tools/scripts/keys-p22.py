import re

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()[:451518].replace(b"\x00", b"\n").decode("latin-1")

keys = [
    "SpringBoard", "backboardd", "WindowServer", "BootUI", "bootui",
    "progress", "lock", "Metal", "softpipe", "rwa", "annibale",
    "no drawable", "initproc", "panic", "kernel data abort",
    "MiniIOMobileFramebuffer: swap", "frames in", "first_frame",
]
for k in keys:
    print("%-32s %d" % (k, data.count(k)))

print("\n=== SpringBoard lines (first 30) ===")
n = 0
for line in data.split("\n"):
    line = line.strip()
    if "SpringBoard" in line:
        print("  ", line[:190])
        n += 1
        if n >= 30:
            break

print("\n=== lines mentioning fail/error/refus/timeout (last 40) ===")
hits = [l.strip() for l in data.split("\n")
        if re.search(r"fail|refus|timeout|could not|cannot|unable", l, re.I)]
print("count", len(hits))
for l in hits[-40:]:
    print("  ", l[:190])
