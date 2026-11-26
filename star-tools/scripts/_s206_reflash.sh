#!/bin/bash
# s206 重刷 + 等待 + 抓取验证 GPU 完成中断接入效果。
# 判据：1) 日志出现 "completion interrupt (SPI 0x12c) is attached"；
#       2) MiniIOMobileFramebuffer 每帧耗时保持 17ms 级不退化；
#       3) Event latency 若存在则从中位 3.44s 降下来。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=C:/ios26
IMG=C:/ios26/s206-boot.img

echo "=== [0] where are we ==="
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [1] wait for fastboot ==="
ok=0
for i in $(seq 1 40); do
  p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true)
  if [ -n "$p" ]; then echo "  bootloader up: $p"; ok=1; break; fi
  sleep 2
done
if [ "$ok" != "1" ]; then echo "NO BOOTLOADER"; exit 1; fi

echo "=== [2] boot s206 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -5

echo "=== [3] wait for loader (xnuloader) ==="
for i in $(seq 1 45); do
  d=$(timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -c 'xnuloader' || true)
  if [ "$d" != "0" ]; then echo "  loader up after $((i*2))s"; break; fi
  sleep 2
done
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [4] wait 9 min for stats window ==="
for i in $(seq 1 27); do
  sleep 20
  echo "  ... $((i*20))s"
done

echo "=== [5] capture staged log ==="
timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
rm -f "$OUT/s206-cur.bin"
timeout 60 "$F" -s xnuloader get_staged "$OUT/s206-cur.bin" 2>&1 | tr -d '\r' | tail -2
sz=$(stat -c%s "$OUT/s206-cur.bin" 2>/dev/null || echo 0)
echo "  size=$sz"

echo "=== [6] analysis ==="
python3 - <<'PY'
import re
p = '/mnt/c/ios26/s206-cur.bin'
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception as e:
    print("cannot read", e); raise SystemExit

print("\n=== [a] GPU completion interrupt attach ===")
for line in d.splitlines():
    if 'completion interrupt' in line.lower() or 'SPI 0x12c' in line:
        print("  ", line.strip())

print("\n=== [b] frame stats ===")
for line in d.splitlines():
    if 'frames in' in line or 'us each in the driver' in line:
        print("  ", line.strip())

print("\n=== [c] panel swap / frame gap ===")
for line in d.splitlines():
    if 'panel swap' in line.lower() or 'half under' in line or 'longest' in line.lower():
        print("  ", line.strip())

print("\n=== [d] Event latency ===")
lats = [int(m) for m in re.findall(r'Event latency:\s*(\d+)', d)]
if lats:
    lats.sort()
    n = len(lats)
    print(f"  events={n} min={lats[0]/1e9:.3f}s median={lats[n//2]/1e9:.3f}s max={lats[-1]/1e9:.3f}s")
else:
    print("  (no Event latency lines — touch interaction may be needed to produce them)")

print("\n=== [e] GPU / adreno health ===")
for line in d.splitlines():
    if 'THE GPU STAYS ON' in line or 'AnnibaleGPU client' in line or 'render pipelines' in line:
        print("  ", line.strip())
PY
