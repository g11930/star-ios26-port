#!/bin/bash
# 帧缓冲转 PNG：1440x3200 BGRA -> 缩放 PNG 两种通道序都存。
set -u
python3 - <<'PY'
from PIL import Image
import struct
w, h = 1440, 3200
raw = open('/mnt/c/ios26/s205-shot.bin','rb').read()
assert len(raw) >= w*h*4, len(raw)
# 尝试 BGRA（小端 ARGB）
img = Image.frombytes('RGBA', (w,h), raw[:w*h*4], 'raw', 'BGRA')
img.save('/mnt/c/ios26/s205-shot-bgra.png')
# 旋转 90 度的版本也存（手机竖屏常见方向问题）
img.rotate(-90, expand=True).save('/mnt/c/ios26/s205-shot-bgra-r.png')
# 统计非黑像素比例
import collections
px = img.convert('RGB')
data = list(px.getdata())
nonblack = sum(1 for p in data if p[0]|p[1]|p[2])
print('nonblack %d/%d = %.1f%%' % (nonblack, len(data), 100.0*nonblack/len(data)))
# 采样 16 个区域的平均色
for yy in range(0, h, h//4):
    row = []
    for xx in range(0, w, w//4):
        row.append(px.getpixel((min(xx,w-1), min(yy,h-1))))
    print(yy, row)
PY
ls -la /mnt/c/ios26/s205-shot*.png
