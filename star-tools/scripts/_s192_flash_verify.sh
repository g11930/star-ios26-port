#!/bin/bash
# Flash s191 (icon-fill fix) and verify icons appear + iconfill counters in log.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s192
cd /mnt/c/ios26 || exit 1

get_staged () { timeout 45 "$F" -s xnuloader get_staged "$1" 2>&1 | tr -d '\r' | tail -1; }
grab () {
  local suf=$1
  echo "=== [$(date +%T)] grab $suf: kernel log first ==="
  rm -f /mnt/c/ios26/${TAG}${suf}-log.bin
  timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}${suf}-log.bin"
  echo "=== [$(date +%T)] grab $suf: screenshot ==="
  rm -f /mnt/c/ios26/${TAG}${suf}-frame.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}${suf}-frame.raw"
  cd /mnt/d/桌面/star26-deps/scripts
  python3 raw2png.py "/mnt/c/ios26/${TAG}${suf}-frame.raw" 2>&1 | grep -E "bytes|not black" | head -2
  cd /mnt/c/ios26
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "android=$ad fastboot=$p"
waitadb () { for i in $(seq 1 30); do ad=$("$A" devices 2>/dev/null | tr -d "\r" | grep -c "device$"); [ "$ad" -ge 1 ] && return 0; sleep 4; done; return 1; }
# If currently in xnuloader, reboot it back to Android first
case "$p" in *xnuloader*)
  echo "in xnuloader -> reboot to Android"
  timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
  waitadb || { echo "WARN: adb not back yet"; }
  sleep 10
  ;;
esac
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) ok=1 ;; esac
if [ "$ok" != "1" ]; then
  echo "going Android -> ABL fastboot"
  waitadb || { echo "ABORT: no android"; exit 2; }
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do
    sleep 2
    p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
    case "$p" in *star*) ok=1; break ;; esac
  done
fi
[ "$ok" != "1" ] && { echo "ABORT: no ABL fastboot"; exit 3; }
echo "ABL ready: $p"

echo "=== [$(date +%T)] boot $TAG ==="
timeout 120 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -2

echo "=== [$(date +%T)] sleep 90 -> early grab ==="
sleep 90
grab "early"

echo "=== [$(date +%T)] sleep 180 -> late grab (after all 6 iconfill passes) ==="
sleep 180
grab "late"

echo "=== [$(date +%T)] ICONFILL STATS (late log) ==="
python3 - <<'PY'
import os,re
p='/mnt/c/ios26/s192late-log.bin'
if not os.path.exists(p): print('NO LOG'); raise SystemExit
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
for l in lines:
    if re.search(r'iconfill|iconview scan|sb26: icons', l):
        print(' ',l.strip()[:220])
print('--- counters ---')
for k in ['error=22','PANIC','KERNEL FAULT','registration device=0','SpringBoard']:
    print('  %-24s %d' % (k, d.count(k)))
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('  last timestamp', ts[-1] if ts else '-')
PY
echo "=== [$(date +%T)] DONE ==="
