#!/bin/bash
# s206 崩溃诊断：重刷 s206，等 4 分钟，抓取启动日志，检查 panic / ISR / 崩溃文本。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=C:/ios26
IMG=C:/ios26/s206-boot.img

echo "=== [0] devices ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [1] boot s206 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [2] wait for loader ==="
for i in $(seq 1 45); do
  d=$(timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -c 'xnuloader' || true)
  if [ "$d" != "0" ]; then echo "  loader up after $((i*2))s"; break; fi
  sleep 2
done
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [3] wait 4 min ==="
for i in $(seq 1 12); do
  sleep 20
  echo "  ... $((i*20))s"
done

echo "=== [4] device still up? ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | tail -1

echo "=== [5] capture staged ==="
timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
rm -f "$OUT/s206-diag.bin"
timeout 60 "$F" -s xnuloader get_staged "$OUT/s206-diag.bin" 2>&1 | tr -d '\r' | tail -2
sz=$(stat -c%s "$OUT/s206-diag.bin" 2>/dev/null || echo 0)
echo "  size=$sz"

echo "=== [6] analysis ==="
python3 - <<'PY'
import re
p = '/mnt/c/ios26/s206-diag.bin'
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception as e:
    print("cannot read", e); raise SystemExit
print("  log lines:", len(d.splitlines()))
print("\n=== [a] panic / crash / fault ===")
hits = [l for l in d.splitlines() if re.search(r'panic|crash|fault|trap|abort|Checker|Kernel  panic|not mapped|Bad|invalid|EL[0-9]|ESR', l, re.I)]
for l in hits[:40]:
    print("  ", l.strip())
if not hits:
    print("  (no panic/fault text)")
print("\n=== [b] ISR attach ===")
for l in d.splitlines():
    if 'completion interrupt' in l.lower() or 'SPI 0x12c' in l:
        print("  ", l.strip())
print("\n=== [c] frame stats ===")
for l in d.splitlines():
    if 'frames in' in l or 'us each in the driver' in l:
        print("  ", l.strip())
print("\n=== [d] GPU health ===")
for l in d.splitlines():
    if 'THE GPU STAYS ON' in l or 'AnnibaleGPU client' in l:
        print("  ", l.strip())
print("\n=== [e] last 25 lines ===")
for l in d.splitlines()[-25:]:
    print("  ", l.strip())
PY
