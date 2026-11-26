#!/bin/bash
# s209 刷写观察：内核 == s208（md5 4f832c1），cmdline 唯一差异 pac_patch=0 -> pac_patch=2。
# 目的：RETAA/RETAB 就地改写成 ret（s203 已验证过 mount-phase-2），砍掉最高频 PAC 陷阱。
# 判据：无 PANIC / 无 mount-phase-2 panic / pac: page 改写存在但 RETAA 不再陷阱 /
#       pac: traps 增速明显低于 s208 的 7.4 亿 / 10 分钟量级；进桌面且时钟分钟级跳动。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
ADB=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s209-boot.img

echo "=== [0] device state ==="
if timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -q xnuloader; then
  echo "  xnuloader present (iOS s208 running) -> oem stop to return to Android"
  timeout 40 "$F" -s xnuloader oem stop 2>&1 | tr -d '\r' | tail -1
  echo "  waiting 40s for Android..."
  sleep 40
fi
timeout 8 "$ADB" devices 2>&1 | tr -d '\r'
if timeout 6 "$F" devices 2>&1 | tr -d '\r' | grep -q fastboot; then
  echo "  already in android fastboot"
else
  echo "  adb reboot bootloader"
  timeout 30 "$ADB" reboot bootloader 2>&1 | tr -d '\r'
  echo "  waiting 35s..."
  sleep 35
fi

echo "=== [1] confirm fastboot (must be android ABL, not xnuloader) ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || {
  echo "  NOT in fastboot"; exit 1
}

echo "=== [2] boot s209 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [3] observe xnuloader 300s (boot to desktop expected within ~4-8 min) ==="
presence=""
for i in $(seq 1 150); do
  sleep 2
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q 'xnuloader'; then
    presence="$presence 1"
  else
    presence="$presence 0"
  fi
  # progress marker every 60s
  if [ $((i % 30)) -eq 0 ]; then echo "  [$((i*2))s] ..."; fi
done
ones=$(echo "$presence" | tr -cd '1' | wc -c)
echo "  xnuloader present samples: $ones/150 (boot survival)"

echo "=== [4] grab staged after ~10 min run ==="
rm -f "$OUT/s209-staged.bin"
if timeout 6 "$F" -s xnuloader devices 2>&1 | tr -d '\r' | grep -q 'xnuloader'; then
  timeout 15 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -1
  timeout 90 "$F" -s xnuloader get_staged "$OUT/s209-staged.bin" 2>&1 | tr -d '\r' | tail -1
else
  echo "  xnuloader gone (possible crash/reset); trying get_staged anyway"
  timeout 90 "$F" -s xnuloader get_staged "$OUT/s209-staged.bin" 2>&1 | tr -d '\r' | tail -1
fi
sz=$(stat -c%s "$OUT/s209-staged.bin" 2>/dev/null || echo 0)
echo "  staged size=$sz"

if [ "$sz" -gt 100 ] && [ "$sz" -lt 5000000 ]; then
  echo "=== [5] staged analysis ==="
  python3 - <<'PY'
import re
p='/mnt/c/ios26/s209-staged.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
print("  log lines:", len(L))
def c(s): return sum(1 for l in L if s in l)
print("  PANIC:", c('PANIC'), "| haltRestart:", c('haltRestart'),
      "| pac: page:", c('pac: page'), "| mount-phase-2:", c('mount-phase-2'),
      "| milestone launchd:", c('star: milestone launchd'),
      "| unlockedEnvironmentMode:", c('unlockedEnvironmentMode'))
# pac traps counters
traps=[l for l in L if 'pac: traps' in l or 'pac: page' in l]
print("  pac counter lines:", len(traps))
for l in traps[-5:]: print("   ", l.strip()[:170])
print("\n  === panic lines ===")
for l in L:
    if 'PANIC' in l or 'haltRestart' in l or 'not a platform binary' in l:
        print("   ", l.strip()[:180])
print("\n  === milestones ===")
for l in L:
    if re.search(r'milestone|THE GPU STAYS|unlockedEnvironment|StarDisk: published|mount-phase-2|render pipelines', l):
        print("   ", l.strip()[:170])
print("\n  === last 15 lines ===")
for l in L[-15:]:
    print("   ", l.strip()[:170])
PY
fi
echo "=== DONE ==="
