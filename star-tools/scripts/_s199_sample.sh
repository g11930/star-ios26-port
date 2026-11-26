#!/bin/bash
# s199 连续采样。每 45 秒抓一次 staged，共 26 轮（约 20 分钟，覆盖整个启动到桌面）。
# 重点：tl: s / tl: v / tl: l / milestone: first_frame 是否终于出现。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=/mnt/c/ios26

echo ">>> s199 sampling start $(date +%H:%M:%S)"
for r in $(seq 1 26); do
  timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f "$OUT/s199mon-$r.bin"
  timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s199mon-$r.bin" >/dev/null 2>&1
  sz=$(stat -c%s "$OUT/s199mon-$r.bin" 2>/dev/null || echo 0)
  ts=$(python3 - "$OUT/s199mon-$r.bin" <<'PY'
import sys,re
try:
    d=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
except Exception:
    print('-'); raise SystemExit
t=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',d)
print(t[-1] if t else '-')
PY
)
  tl=$(python3 - "$OUT/s199mon-$r.bin" <<'PY'
import sys
try: d=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
except Exception: print('0/0/0'); raise SystemExit
print('%d/%d/%d'%(d.count('tl: s '),d.count('tl: v '),d.count('tl: l ')))
PY
)
  echo "$(date +%H:%M:%S)  r=$r  size=$sz  last=$ts  tls/tlv/tll=$tl"
  sleep 45
done
echo ">>> s199 sampling done $(date +%H:%M:%S)"
