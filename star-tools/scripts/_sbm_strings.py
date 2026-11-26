#!/usr/bin/env python3
import re

path = "/root/star26/s44/work/root/lib/libannibale-sbmetal-experiment.dylib"
d = open(path, "rb").read()
print("size:", len(d))

# printable strings, min length 6
strs = re.findall(rb"[ -~]{6,200}", d)
words = [s.decode("ascii", "replace") for s in strs]
print("total strings:", len(words))
print()
print("== env / boot-arg style keys ==")
for w in words:
    if re.match(r"^[A-Z][A-Z0-9_]{3,}$", w) or "ANNIBALE" in w:
        print("  ", w)
print()
print("== lines that look like printf format (contain % or ': ') ==")
for w in words:
    if ("%" in w) or re.match(r"^[a-z0-9]+: ", w):
        print("  ", w[:150])
