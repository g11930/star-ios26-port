#!/bin/bash
# s207 隔离刷写观察：cmdline gpu_irq=0 跳过 ISR 注册，只保留 gpu_pause 睡眠。
# 目的：隔离 3 秒崩溃来源。
#   - s207 不崩 => 崩溃由 ISR 注册 (gic_v3_spi_attach / gpu_completion_isr) 引起
#   - s207 仍崩 => 崩溃由 gpu_pause 真实睡眠 / 新代码引起
# 不 reboot 清 staged；刷写后持续探测 xnuloader，记录出现/消失模式。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
ADB=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s207-boot.img

echo "=== [0] device on Android; reboot to bootloader ==="
timeout 30 "$ADB" reboot bootloader 2>&1 | tr -d '\r'
echo "  waiting 35s for bootloader..."
sleep 35

echo "=== [1] confirm fastboot ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || {
  echo "  NOT in fastboot after reboot"; exit 1
}

echo "=== [2] boot s207 (gpu_irq=0, ISR skipped) ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [3] observe xnuloader presence 90s (1=present 0=gone) ==="
presence=""
for i in $(seq 1 45); do
  sleep 2
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q 'xnuloader'; then
    presence="$presence 1"
  else
    presence="$presence 0"
    echo "  [$((i*2))s] xnuloader gone"
  fi
done

echo "=== [4] presence pattern ==="
echo "$presence"
max_run=0; cur=0
for c in $presence; do
  if [ "$c" = "1" ]; then cur=$((cur+1)); else cur=0; fi
  [ "$cur" -gt "$max_run" ] && max_run=$cur
done
echo "  max continuous presence: $((max_run*2))s"

if [ "$max_run" -ge 15 ]; then
  echo "=== RESULT: s207 did NOT crash (max presence $((max_run*2))s) ==="
  echo "  => crash caused by ISR attach (gic_v3_spi_attach / gpu_completion_isr)"
else
  echo "=== RESULT: s207 STILL crashes (max presence $((max_run*2))s) ==="
  echo "  => crash from gpu_pause sleep / new code, NOT ISR"
fi

echo "=== [5] grab staged if xnuloader present ==="
if timeout 6 "$F" -s xnuloader devices 2>&1 | tr -d '\r' | grep -q 'xnuloader'; then
  rm -f "$OUT/s207-staged.bin"
  timeout 45 "$F" -s xnuloader get_staged "$OUT/s207-staged.bin" 2>&1 | tr -d '\r' | tail -1
  sz=$(stat -c%s "$OUT/s207-staged.bin" 2>/dev/null || echo 0)
  echo "  staged size=$sz"
  if [ "$sz" -gt 100 ]; then
    echo "=== [6] staged analysis ==="
    python3 - <<'PY'
import re
p = '/mnt/c/ios26/s207-staged.bin'
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception as e:
    print("  cannot read", e); raise SystemExit
lines = d.splitlines()
print("  log lines:", len(lines))
print("=== panic/crash/fault hits ===")
hits = [l for l in lines if re.search(r'panic|crash|fault|trap|abort|Checker|not mapped|Bad|invalid|ESR|EL[0-9]|Unexpected|Assertion|died|deadlock|timeout', l, re.I)]
for l in hits[:40]:
    print("  ", l.strip())
if not hits:
    print("  (none)")
print("=== adreno / gpu steps ===")
for l in lines:
    if 'adreno' in l.lower() or 'completion interrupt' in l.lower() or 'SPI 0x12c' in l or 'THE GPU STAYS ON' in l:
        print("  ", l.strip())
print("=== last 25 lines ===")
for l in lines[-25:]:
    print("  ", l.strip())
PY
  fi
fi
echo "=== DONE ==="
