#!/bin/bash
# 手动抓取 s205 staged 日志：路径必须用 Windows 形式传给 fastboot.exe。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
WIN_OUT=C:/ios26/s205b-2.bin
LINUX_OUT=/mnt/c/ios26/s205b-2.bin

echo "=== device check ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== compose fresh (kernel alive ~12 min now) ==="
timeout 20 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2

echo "=== get_staged ==="
rm -f "$LINUX_OUT"
timeout 60 "$F" -s xnuloader get_staged "$WIN_OUT" 2>&1 | tr -d '\r' | tail -2
sz=$(stat -c%s "$LINUX_OUT" 2>/dev/null || echo 0)
echo "size=$sz"

if [ "$sz" -gt 1000 ]; then
  echo "=== quick analysis ==="
  python3 - <<'PY'
import re
d = open('/mnt/c/ios26/s205b-2.bin','rb').read().decode('utf-8','replace').replace('\0','')
ts = re.findall(r'2025-\d\d-\d\d \d\d:\d\d:\d\d', d)
print('last_ts=%s  bytes=%d' % (ts[-1] if ts else '-', len(d)))
frames = re.findall(r'MiniIOMobileFramebuffer: (\d+) frames in (\d+) ms \((\d+) a second\), (\d+) us each in the driver[^;]*; (\d+) us waiting for the GPU', d)
for f in frames[-4:]:
    print('frames:', f)
diff = re.findall(r'(\d+) pixels of the panel changed a frame', d)
print('diff_pixels(last4)=', diff[-4:])
p34 = re.findall(r'P34: panel swap (\d+)[^\n]*', d)
for p in p34[-3:]:
    print('P34:', p[:100])
tlv = re.findall(r'tl: v (\d+) ready \d+ shown \d+ done \d+', d)
print('tlv(last4)=', tlv[-4:])
# 首帧行
for m in re.findall(r'[^\n]*first[ _-]frame[^\n]*', d, re.I)[-3:]:
    print('first_frame:', m[:120])
PY
fi
echo "=== done ==="
