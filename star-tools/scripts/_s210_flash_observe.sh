#!/bin/bash
# s210 刷写 + 高频崩溃监控。
# s210 = s209 的 cmdline(pac_patch=2) + 新内核(类别掩码 sleh.c, md5 75637f41)。
# 唯一变量是内核的 pac_patch 语义：s209 布尔(非零=全开,崩), s210 掩码(2=只改RETAA)。
# 判据：过 mount-phase-2 无 panic；pac: page instrs 非0；pac: traps 增速远低于 s208。
# 崩溃高发在前 3 分钟(s209 是 122s)，所以高频监控 + 崩溃瞬间立刻抓 staged。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
ADB=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=C:/ios26
IMG=C:/ios26/s210-boot.img
STAGED="$OUT/s210-staged.bin"

grab_staged() {
  local tag="$1"
  rm -f "/mnt/c/ios26/s210-staged.bin"
  echo "  [grab $tag] oem log + get_staged ..."
  timeout 15 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -1
  timeout 90 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -1
  local sz=$(stat -c%s "/mnt/c/ios26/s210-staged.bin" 2>/dev/null || echo 0)
  echo "  [grab $tag] size=$sz"
  if [ "$sz" -gt 100 ]; then cp -f "/mnt/c/ios26/s210-staged.bin" "/mnt/c/ios26/s210-$tag.bin"; fi
}

echo "=== [0] device state ==="
if timeout 8 "$F" devices 2>&1 | tr -d '\r' | grep -q xnuloader; then
  echo "  xnuloader present (s208 running) -> oem stop to Android"
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

echo "=== [1] confirm fastboot (android ABL, getvar product) ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -m1 'product:' || { echo "  NOT in fastboot"; exit 1; }

echo "=== [2] boot s210 ==="
echo "  image sha256: $(sha256sum /mnt/c/ios26/s210-boot.img | cut -d' ' -f1)"
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3

echo "=== [3] monitor xnuloader 360s, grab staged the instant it disappears ==="
ones=0; zeros=0; crashed=0
for i in $(seq 1 180); do
  sleep 2
  d=$(timeout 6 "$F" devices 2>&1 | tr -d '\r')
  if echo "$d" | grep -q xnuloader; then
    ones=$((ones+1))
    # alive: refresh staged every 30s so we always have a recent snapshot
    if [ $((i % 15)) -eq 0 ]; then grab_staged "alive$((i*2))"; fi
  else
    zeros=$((zeros+1))
    if [ "$crashed" -eq 0 ] && [ "$ones" -gt 2 ]; then
      echo "  *** xnuloader GONE at $((i*2))s (ones=$ones) -> crash/reset suspected ***"
      crashed=1
      # try immediate staged grab (may still be in DRAM)
      timeout 60 "$F" -s xnuloader get_staged "$STAGED" 2>&1 | tr -d '\r' | tail -1
      sz=$(stat -c%s "/mnt/c/ios26/s210-staged.bin" 2>/dev/null || echo 0)
      echo "  emergency staged size=$sz"
      [ "$sz" -gt 100 ] && cp -f "/mnt/c/ios26/s210-staged.bin" "/mnt/c/ios26/s210-crash-$((i*2))s.bin"
    fi
  fi
  if [ $((i % 30)) -eq 0 ]; then echo "  [$((i*2))s] present=$ones absent=$zeros crashed=$crashed"; fi
done
echo "  FINAL: present=$ones/180 absent=$zeros crashed=$crashed"

echo "=== [4] final staged grab if still alive ==="
if timeout 6 "$F" -s xnuloader devices 2>&1 | tr -d '\r' | grep -q xnuloader; then
  grab_staged "final"
fi

echo "=== [5] analyze all captured stages ==="
python3 - <<'PY'
import glob, re, os
files = sorted(glob.glob('/mnt/c/ios26/s210-*.bin'))
# prefer the largest capture (most complete log)
best = max(files, key=lambda p: os.path.getsize(p)) if files else None
print("  captures:", [(os.path.basename(f), os.path.getsize(f)) for f in files])
if not best:
    print("  NO staged captures"); raise SystemExit
d = open(best,'rb').read().decode('utf-8','replace').replace('\0','')
L = d.splitlines()
print("  analyzing:", os.path.basename(best), "| lines:", len(L))
def c(s): return sum(1 for l in L if s in l)
print("  PANIC:", c('PANIC'), "| haltRestart:", c('haltRestart'),
      "| pac: page:", c('pac: page'), "| mount-phase-2:", c('mount-phase-2'),
      "| not a platform binary:", c('not a platform binary'),
      "| unlockedEnvironmentMode:", c('unlockedEnvironmentMode'),
      "| SpringBoard:", c('SpringBoard'), "| render pipelines:", c('render pipelines'))
traps = [l for l in L if 'pac: traps' in l]
nums = [int(m.group(1)) for l in traps for m in [re.search(r'traps=(\d+)', l)] if m]
print("  pac traps counter lines:", len(traps), "| last value:", nums[-1] if nums else 0)
pages = [l for l in L if 'pac: page' in l]
print("  pac: page rewrite lines:", len(pages))
for l in pages[:6]: print("   ", l.strip()[:160])
print("  --- panic lines ---")
for l in L:
    if 'PANIC' in l or 'haltRestart' in l or 'not a platform binary' in l:
        print("   ", l.strip()[:180])
print("  --- milestones ---")
for l in L:
    if re.search(r'milestone|THE GPU STAYS|unlockedEnvironment|StarDisk: published|render pipelines', l):
        print("   ", l.strip()[:170])
print("  --- last 12 ---")
for l in L[-12:]: print("   ", l.strip()[:170])
PY
echo "=== DONE ==="
