#!/usr/bin/env python3
import re
p = "/root/star26/s42/work/root/lib/libannibalemetal.dylib"
d = open(p, "rb").read()
ss = [m.group().decode("ascii","replace") for m in re.finditer(rb"[\x20-\x7e]{5,}", d)]
pat = re.compile(r"ANNIBALE_DUMP_AIR|ANNIBALE_DIAG|dump|diag|/private/var|\.air|\.metallib|write", re.I)
seen = set()
for s in ss:
    if pat.search(s) and s not in seen:
        seen.add(s)
        print("  ", s[:170])
print("count", len(seen))
