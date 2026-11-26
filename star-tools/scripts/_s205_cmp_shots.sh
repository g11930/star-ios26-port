#!/bin/bash
# 对比两次截图 + 新图结构分析。
set -u
python3 - <<'PY'
from PIL import Image, ImageChops
a = Image.open('/mnt/c/ios26/s205-shot-bgra.png').convert('RGB')
b = Image.open('/mnt/c/ios26/s205-shot2-bgra.png').convert('RGB')
diff = ImageChops.difference(a, b)
d = list(diff.getdata())
changed = sum(1 for p in d if p[0]|p[1]|p[2] > 8)
print('changed pixels: %d / %d = %.2f%%' % (changed, len(d), 100.0*changed/len(d)))
print('diff bbox:', diff.convert('L').getbbox())

w, h = b.size
px = b.load()
prev = None
for y in range(0, h, 16):
    vals = [px[x, y] for x in range(0, w, 24)]
    mean = tuple(sum(c[i] for c in vals)//len(vals) for i in range(3))
    white = sum(1 for c in vals if min(c)>250) / len(vals)
    dark = sum(1 for c in vals if max(c)<60) / len(vals)
    band = 'WHITE' if white > 0.5 else ('DARK' if dark > 0.5 else 'grey')
    if band != prev:
        print('%4d %s white=%.0f%% dark=%.0f%%' % (y, mean, white*100, dark*100))
        prev = band
# 彩色像素（图标特征）：饱和度高的像素
sat = sum(1 for p in b.getdata() if max(p)-min(p) > 60)
print('saturated(colorful) pixels: %d (%.2f%%)' % (sat, 100.0*sat/(w*h)))
PY
