#!/bin/bash
# s206 3秒崩溃抢抓 v2：boot 后持续探测 xnuloader，一出现立即 get_staged，绝不 adb reboot（避免清 staged）。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=C:/ios26
IMG=C:/ios26/s206-boot.img

echo "=== [0] ensure fastboot ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || {
  echo "  not in fastboot"; exit 1
}

echo "=== [1] boot s206 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [2] poll xnuloader, grab staged the moment it appears (up to 120s) ==="
grabbed=0
for i in $(seq 1 40); do
  sleep 2
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q 'xnuloader'; then
    echo "  [$((i*2))s] xnuloader present"
    if [ "$grabbed" = "0" ]; then
      rm -f "$OUT/s206-crash.bin"
      timeout 45 "$F" -s xnuloader get_staged "$OUT/s206-crash.bin" 2>&1 | tr -d '\r' | tail -1
      sz=$(stat -c%s "$OUT/s206-crash.bin" 2>/dev/null || echo 0)
      echo "  grabbed staged: size=$sz"
      grabbed=1
    fi
  else
    echo "  [$((i*2))s] xnuloader gone (crash cycle)"
  fi
done

echo "=== [3] analysis ==="
python3 - <<'PY'
import re
p = '/mnt/c/ios26/s206-crash.bin'
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception as e:
    print("  cannot read", e); raise SystemExit
lines = d.splitlines()
print("  log lines:", len(lines))
print("\n=== [a] panic / crash / fault / trap ===")
hits = [l for l in lines if re.search(r'panic|crash|fault|trap|abort|Checker|not mapped|Bad|invalid|ESR|EL[0-9]|Unexpected|Assertion|died|deadlock|timeout', l, re.I)]
for l in hits[:60]:
    print("  ", l.strip())
if not hits:
    print("  (none)")
print("\n=== [b] ISR attach / adreno steps ===")
for l in lines:
    if 'completion interrupt' in l.lower() or 'SPI 0x12c' in l or 'adreno: step' in l or 'THE GPU STAYS ON' in l:
        print("  ", l.strip())
print("\n=== [c] last 30 lines ===")
for l in lines[-30:]:
    print("  ", l.strip())
PY
