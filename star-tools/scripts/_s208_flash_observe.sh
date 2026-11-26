#!/bin/bash
# s208 刷写观察：cmdline 只比 s207 多 pac_patch=0（关闭 PAC 页改写），内核同一份。
# 判据：是否越过 s207 卡死的 mount-phase-2，且日志无 PANIC、无 pac: page 改写。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
ADB=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s208-boot.img

echo "=== [0] device state ==="
timeout 8 "$ADB" devices 2>&1 | tr -d '\r'
if timeout 6 "$F" devices 2>&1 | tr -d '\r' | grep -q fastboot; then
  echo "  already in fastboot"
else
  echo "  reboot to bootloader"
  timeout 30 "$ADB" reboot bootloader 2>&1 | tr -d '\r'
  echo "  waiting 35s..."
  sleep 35
fi

echo "=== [1] confirm fastboot ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || {
  echo "  NOT in fastboot"; exit 1
}

echo "=== [2] boot s208 ==="
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [3] observe xnuloader 120s (1=present 0=gone) ==="
presence=""
for i in $(seq 1 60); do
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

echo "=== [5] grab staged ==="
rm -f "$OUT/s208-staged.bin"
if timeout 6 "$F" -s xnuloader devices 2>&1 | tr -d '\r' | grep -q 'xnuloader'; then
  timeout 60 "$F" -s xnuloader get_staged "$OUT/s208-staged.bin" 2>&1 | tr -d '\r' | tail -1
else
  echo "  xnuloader not present now; trying anyway"
  timeout 60 "$F" -s xnuloader get_staged "$OUT/s208-staged.bin" 2>&1 | tr -d '\r' | tail -1
fi
sz=$(stat -c%s "$OUT/s208-staged.bin" 2>/dev/null || echo 0)
echo "  staged size=$sz"

if [ "$sz" -gt 100 ] && [ "$sz" -lt 5000000 ]; then
  echo "=== [6] staged analysis ==="
  python3 - <<'PY'
import re
p='/mnt/c/ios26/s208-staged.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()
print("  log lines:", len(L))
def c(s): return sum(1 for l in L if s in l)
print("  PANIC:", c('PANIC'), "| haltRestart:", c('haltRestart'),
      "| pac: page:", c('pac: page'), "| mount-phase-2:", c('mount-phase-2'),
      "| milestone launchd:", c('star: milestone launchd'),
      "| unlockedEnvironmentMode:", c('unlockedEnvironmentMode'),
      "| SpringBoard:", c('SpringBoard'))
print("\n  === panic lines ===")
for l in L:
    if 'PANIC' in l or 'haltRestart' in l or 'not a platform binary' in l:
        print("   ", l.strip()[:180])
print("\n  === milestones / display / gpu ===")
for l in L:
    if re.search(r'milestone|THE GPU STAYS|gpu_irq=0|unlockedEnvironment|StarDisk: published|mount-phase-2|SpringBoard\[', l):
        print("   ", l.strip()[:170])
print("\n  === last 20 lines ===")
for l in L[-20:]:
    print("   ", l.strip()[:170])
PY
elif [ "$sz" -ge 5000000 ]; then
  echo "  (large buffer = framebuffer; converting to screen png)"
  wsl_py() { :; }
  python3 - <<'PY'
from PIL import Image
p='/mnt/c/ios26/s208-staged.bin'
d=open(p,'rb').read()
W,H=1440,3200
if len(d)>=W*H*4:
    im=Image.frombytes('RGBA',(W,H),d[:W*H*4],'raw','BGRA').convert('RGB')
    im.save('/mnt/c/ios26/s208-screen.png')
    im.resize((360,800)).save('/mnt/c/ios26/s208-screen-small.png')
    print("  saved s208-screen.png")
else:
    print("  buffer too small for framebuffer:", len(d))
PY
fi
echo "=== DONE ==="
