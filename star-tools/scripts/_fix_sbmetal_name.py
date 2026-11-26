#!/usr/bin/env python3
K = "/root/star26/star-native/bsd/kern/kern_exec.c"
data = open(K, encoding="utf-8").read()
old = "\tif (star_sbmetal && used + 1 + 50 < size &&"
new = "\tif (star_sbmetal_enabled && used + 1 + 50 < size &&"
cnt = data.count(old)
data = data.replace(old, new, 1)
open(K, "w", encoding="utf-8").write(data)
print("replaced:", cnt)
