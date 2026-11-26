#!/usr/bin/env python3
a = open("/root/star26/baseline/s208parts/ramdisk", "rb").read()
b = open("/tmp/s208-repro.apfs", "rb").read()
diff = [i for i in range(len(a)) if a[i] != b[i]]
print("size %d %d, diff bytes %d" % (len(a), len(b), len(diff)))
# group into ranges
ranges = []
start = prev = diff[0]
for i in diff[1:]:
    if i == prev + 1:
        prev = i
    else:
        ranges.append((start, prev))
        start = prev = i
ranges.append((start, prev))
print("diff ranges (offset):")
for s, e in ranges[:40]:
    print("  0x%08x-0x%08x (%d bytes)  A=%s B=%s" % (s, e, e-s+1, a[s:e+1][:24].hex(), b[s:e+1][:24].hex()))
print("total ranges:", len(ranges))
# Are any diffs above the superblock area (say > 1MB)?
print("diffs above 1MB:", sum(1 for i in diff if i > 1024*1024))
print("max diff offset:", max(diff))
