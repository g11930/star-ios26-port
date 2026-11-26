#!/bin/bash
# s211 = s210 cmdline(pac_patch=2) + 新内核(类别掩码 + FIPS 相位闸门, md5 62f2cff2)
# 核心验证：FIPS 闸门是否让启动越过 fips boot task 继续到桌面。
#   判据1: FIPS integrity 之后出现 "Returned from calling the FIPS_POST ... result = true"
#          以及后续 keybagd / SpringBoard / render pipelines（s210 卡在这里没有）
#   判据2: pac: page 改写只在 FIPS 之后出现（FIPS 前应为 0 页）
#   判据3: 最终进桌面、pac: traps 增速远低于 s208
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
ADB=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s211-boot.img
STAGED="$OUT/s211-staged.bin"

grab_staged() {
  local tag="$1"
  rm -f "/mnt/c/ios26/s211-staged.bin"
  timeout 15 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 90 "$F" -s xnuloader get_staged "$STAGED" >/dev/null 2>&1
  local sz=$(stat -c%s "/mnt/c/ios26/s211-staged.bin" 2>/dev/null || echo 0)
  echo "  [grab $tag] size=$sz"
  if [ "$sz" -gt 100 ]; then cp -f "/mnt/c/ios26/s211-staged.bin" "/mnt/c/ios26/s211-$tag.bin"; fi
}

echo "=== [0] device state ==="
if timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -q xnuloader; then
  echo "  xnuloader present -> oem stop to Android"
  timeout 40 "$F" -s xnuloader oem stop 2>&1 | tr -d '\r' | tail -1
  sleep 40
fi
if timeout 6 "$F" devices 2>&1 | tr -d '\r' | grep -q fastboot; then
  echo "  already in android fastboot"
else
  echo "  adb reboot bootloader"
  timeout 30 "$ADB" reboot bootloader 2>&1 | tr -d '\r'
  sleep 35
fi
echo "=== [1] confirm fastboot ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || { echo "NOT in fastboot"; exit 1; }

echo "=== [2] boot s211 ==="
echo "  image sha256: $(sha256sum /mnt/c/ios26/s211-boot.img | cut -d' ' -f1)"
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -2

echo "=== [3] monitor 480s (FIPS gate: expect boot to CONTINUE past fips) ==="
ones=0; zeros=0; crashed=0
for i in $(seq 1 240); do
  sleep 2
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q xnuloader; then
    ones=$((ones+1))
    if [ $((i % 15)) -eq 0 ]; then grab_staged "alive$((i*2))"; fi
  else
    zeros=$((zeros+1))
    if [ "$crashed" -eq 0 ] && [ "$ones" -gt 2 ]; then
      echo "  *** xnuloader GONE at $((i*2))s (ones=$ones) ***"
      crashed=1
      timeout 60 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -1
      sz=$(stat -c%s "/mnt/c/ios26/s211-staged.bin" 2>/dev/null || echo 0)
      [ "$sz" -gt 100 ] && cp -f "/mnt/c/ios26/s211-staged.bin" "/mnt/c/ios26/s211-crash-$((i*2))s.bin"
    fi
  fi
  [ $((i % 30)) -eq 0 ] && echo "  [$((i*2))s] present=$ones absent=$zeros crashed=$crashed"
done
echo "  FINAL present=$ones/240 absent=$zeros crashed=$crashed"

echo "=== [4] final grab ==="
if timeout 6 "$F" -s xnuloader devices 2>&1 | tr -d '\r' | grep -q xnuloader; then
  grab_staged "final"
fi

echo "=== [5] analyze: did FIPS gate work? ==="
python3 - <<'PY'
import glob, re, os
files = sorted(glob.glob('/mnt/c/ios26/s211-*.bin'))
if not files:
    print("  NO captures"); raise SystemExit
best = max(files, key=lambda p: os.path.getsize(p))
print("  captures:", [(os.path.basename(f), os.path.getsize(f)) for f in files][-6:])
print("  analyzing:", os.path.basename(best))
d = open(best,'rb').read().decode('utf-8','replace').replace('\0','')
L = d.splitlines()
def c(s): return sum(1 for l in L if s in l)
print("  lines:", len(L))
print("  === KEY: FIPS gate ===")
print("  FIPS_POST returned(true):", c('Returned from calling the FIPS_POST'),
      "| fips integrity FAILED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'FAILED' in l),
      "| fips integrity PASSED:", sum(1 for l in L if 'fipspost_post_integrity' in l and 'PASSED' in l))
print("  === progress markers ===")
for k in ['keybagd','MKB_INIT','SpringBoard','backboardd','render pipelines','THE GPU STAYS','unlockedEnvironmentMode','mount-phase-2']:
    print(f"    {k}: {c(k)}")
print("  === crash markers ===")
for k in ['PANIC','haltRestart','not a platform binary']:
    print(f"    {k}: {c(k)}")
# pac: page vs FIPS ordering
fi = [i for i,l in enumerate(L) if 'FIPSPOST' in l and 'Module-ID' in l]
pi = [i for i,l in enumerate(L) if 'pac: page' in l]
print("  === pac:page vs FIPS ordering ===")
if fi and pi:
    print(f"    FIPS at line {fi[0]} | first pac:page at {pi[0]} | pages before FIPS: {sum(1 for i in pi if i<fi[0])} | after: {sum(1 for i in pi if i>fi[0])}")
elif pi:
    print(f"    pac:page {len(pi)} lines, FIPS not yet reached (line {pi[0]}..)")
else:
    print("    no pac:page, no FIPS yet")
traps=[int(m.group(1)) for l in L for m in [re.search(r'traps=(\d+)',l)] if m]
print("    pac traps last:", traps[-1] if traps else 0)
print("  === last 12 (non-tl/pac) ===")
n=0
for l in reversed(L):
    s=l.strip()
    if not s or 'tl: c' in s or 'pac:' in s: continue
    print("   ", s[:165]); n+=1
    if n>=12: break
PY
echo "=== DONE ==="
