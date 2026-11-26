#!/usr/bin/env python3
import re
NEW = "/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/src/gallium/drivers/freedreno/libannibaleair.dylib"
OLD = "/root/star26/s42/chk/lib/libannibaleair.dylib".replace("/s42/chk", "/s41/work/root")

def strs(p, minlen=12):
    d = open(p, "rb").read()
    return set(m.group().decode("ascii", "replace") for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, d))

a = strs(NEW); b = strs(OLD)
only_new = sorted(a - b)
only_old = sorted(b - a)
print("new=%d old=%d  only_new=%d only_old=%d" % (len(a), len(b), len(only_new), len(only_old)))
print("\n== only in NEW (first 45) ==")
for s in only_new[:45]:
    print("  +", s[:170])
print("\n== only in OLD (first 25) ==")
for s in only_old[:25]:
    print("  -", s[:170])
