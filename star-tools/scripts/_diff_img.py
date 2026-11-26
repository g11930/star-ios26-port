#!/usr/bin/env python3
a = open('/mnt/c/ios26/s200-boot.img', 'rb').read()
b = open('/mnt/c/ios26/s211-boot.img', 'rb').read()
print(len(a), len(b))
diff = [i for i in range(len(a)) if a[i] != b[i]]
print('diff bytes', len(diff), 'first', diff[:8], 'last', diff[-8:] if diff else None)
# find contiguous regions
if diff:
    regions = []
    s = diff[0]; p = diff[0]
    for i in diff[1:]:
        if i - p > 64:
            regions.append((s, p)); s = i
        p = i
    regions.append((s, p))
    print('regions', [(r[0], r[1], r[1]-r[0]+1) for r in regions][:10])
