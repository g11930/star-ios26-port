#!/bin/bash
# s206 3秒崩溃快速抢抓：boot 后持续探测，设备一旦掉回 Android 立即切回取 staged。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s206-boot.img

echo "=== [0] ensure fastboot ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || {
  echo "  not in fastboot; adb reboot bootloader"
  "$A" reboot bootloader 2>&1 | tr -d '\r'
  for i in $(seq 1 30); do sleep 2; p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true); [ -n "$p" ] && { echo "  back: $p"; break; }; done
}

echo "=== [1] boot s206 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [2] poll loader + crash window (every 3s, up to 90s) ==="
for i in $(seq 1 30); do
  sleep 3
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q 'xnuloader'; then
    echo "  [$((i*3))s] still xnuloader"
  else
    echo "  [$((i*3))s] DEVICE GONE (crash) -> switch back & grab"
    break
  fi
done

echo "=== [3] switch back to bootloader ==="
"$A" reboot bootloader 2>&1 | tr -d '\r'
for i in $(seq 1 30); do sleep 2; p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || true); [ -n "$p" ] && { echo "  back: $p"; break; }; done
timeout 8 "$F" devices 2>&1 | tr -d '\r'

echo "=== [4] grab staged (crashed DRAM) ==="
rm -f "$OUT/s206-crash.bin"
timeout 60 "$F" -s xnuloader get_staged "$OUT/s206-crash.bin" 2>&1 | tr -d '\r' | tail -2
sz=$(stat -c%s "$OUT/s206-crash.bin" 2>/dev/null || echo 0)
echo "  size=$sz"

echo "=== [5] analysis ==="
python3 - <<'PY'
import re
p = '/mnt/c/ios26/s206-crash.bin'
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception as e:
    print("  cannot read", e); raise SystemExit
print("  log lines:", len(d.splitlines()))
print("\n=== [a] panic / crash / fault / trap ===")
hits = [l for l in d.splitlines() if re.search(r'panic|crash|fault|trap|abort|Checker|not mapped|Bad|invalid|ESR|EL[0-9]|Unexpected|Assertion|died', l, re.I)]
for l in hits[:50]:
    print("  ", l.strip())
if not hits:
    print("  (none)")
print("\n=== [b] ISR attach / adreno lines ===")
for l in d.splitlines():
    if 'completion interrupt' in l.lower() or 'SPI 0x12c' in l or 'adreno: step' in l or 'THE GPU STAYS ON' in l:
        print("  ", l.strip())
print("\n=== [c] last 30 lines ===")
for l in d.splitlines()[-30:]:
    print("  ", l.strip())
PY
