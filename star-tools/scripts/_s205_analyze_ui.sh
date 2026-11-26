#!/bin/bash
# 屏幕结构分析：行亮度剖面 + 分区裁剪，判断界面类型。
set -u
python3 - <<'PY'
from PIL import Image
w, h = 1440, 3200
img = Image.open('/mnt/c/ios26/s205-shot-bgra.png').convert('RGB')

# 每行平均亮度与白色占比，找 UI 带状结构
rows = []
px = img.load()
for y in range(0, h, 16):
    vals = [px[x, y] for x in range(0, w, 24)]
    mean = tuple(sum(c[i] for c in vals)//len(vals) for i in range(3))
    white = sum(1 for c in vals if c[0]>250 and c[1]>250 and c[2]>250) / len(vals)
    dark  = sum(1 for c in vals if c[0]<60 and c[1]<60 and c[2]<60) / len(vals)
    rows.append((y, mean, white, dark))

# 压缩成带：按 white 占比分类
print('y     mean_rgb        white%  dark%  band')
prev = None
for y, m, wh, dk in rows:
    band = 'WHITE' if wh > 0.5 else ('DARK' if dk > 0.5 else 'grey')
    if band != prev:
        print('%4d  %s  %5.1f  %5.1f  %s' % (y, m, wh*100, dk*100, band))
        prev = band

# 状态栏区域检测（顶部 120px 是否有内容）
top = img.crop((0, 0, w, 130))
tb = list(top.getdata())
dark_top = sum(1 for p in tb if p[0]<100) / len(tb)
print('\ntop-130px dark ratio: %.3f (status bar text?)' % dark_top)

# 裁剪关键区域供查看
img.crop((0, 0, w, 640)).save('/mnt/c/ios26/s205-crop-top.png')
img.crop((0, h//2-320, w, h//2+320)).save('/mnt/c/ios26/s205-crop-mid.png')
img.crop((0, h-640, w, h)).save('/mnt/c/ios26/s205-crop-bot.png')

# 中心区大字体检测：找最暗的行（大段文字/大时钟）
darkest = sorted(rows, key=lambda r: r[3])[-5:]
print('darkest rows (y, dark%):', [(r[0], round(r[3]*100)) for r in darkest])
PY
ls -la /mnt/c/ios26/s205-crop-*.png
