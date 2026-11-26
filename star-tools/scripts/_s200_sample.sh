#!/bin/bash
# s200 连续采样。每 40 秒抓一次 staged，共 24 轮（约 16 分钟，覆盖启动到桌面）。
# 重点：fb_diff 的 "pixels of the panel changed a frame" 是否出现、数值多少；
#       以及 tl: s / tl: v 的走势。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=/mnt/c/ios26

echo ">>> s200 sampling start $(date +%H:%M:%S)"
for r in $(seq 1 24); do
  timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f "$OUT/s200mon-$r.bin"
  timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s200mon-$r.bin" >/dev/null 2>&1
  sz=$(stat -c%s "$OUT/s200mon-$r.bin" 2>/dev/null || echo 0)
  info=$(python3 - "$OUT/s200mon-$r.bin" <<'PY'
import sys,re
try:
    d=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
except Exception:
    print('-  0/0/0 d=0 f=0'); raise SystemExit
t=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',d)
last=t[-1] if t else '-'
diffs=re.findall(r'(\d+) pixels of the panel changed a frame',d)
dv=diffs[-1] if diffs else 'None'
print('%s  tls/tlv/tll=%d/%d/%d  diff=%s  frames=%d' % (
    last, d.count('tl: s '), d.count('tl: v '), d.count('tl: l '), dv, d.count('frames in ')))
PY
)
  echo "$(date +%H:%M:%S)  r=$r  size=$sz  $info"
  sleep 40
done
echo ">>> s200 sampling done $(date +%H:%M:%S)"
