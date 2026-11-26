#!/bin/bash
# Flash s193 and wait for desktop, then grab log and check STM touch evidence.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s195
cd /mnt/c/ios26 || exit 1

get_staged () { timeout 45 "$F" -s xnuloader get_staged "$1" 2>&1 | tr -d '\r' | tail -1; }
grab () {
  echo "=== [$(date +%T)] grab log ==="
  rm -f /mnt/c/ios26/${TAG}-log.bin
  timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}-log.bin"
  echo "=== [$(date +%T)] grab frame ==="
  rm -f /mnt/c/ios26/${TAG}-frame.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}-frame.raw"
  cd /mnt/d/桌面/star26-deps/scripts
  python3 raw2png.py "/mnt/c/ios26/${TAG}-frame.raw" 2>&1 | grep -E "not black" | head -1
  cd /mnt/c/ios26
}

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1; sleep 1
waitadb () { for i in $(seq 1 30); do ad=$("$A" devices 2>/dev/null | tr -d "\r" | grep -c "device$"); [ "$ad" -ge 1 ] && return 0; sleep 4; done; return 1; }
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "fastboot: $p"
case "$p" in *xnuloader*)
  echo "in loader -> reboot to Android"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; waitadb; sleep 10 ;;
esac
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) ok=1 ;; esac
if [ "$ok" != "1" ]; then
  waitadb || { echo ABORT-no-android; exit 2; }
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) ok=1; break ;; esac; done
fi
[ "$ok" != "1" ] && { echo ABORT-no-ABL; exit 3; }
echo "ABL: $p"

echo "=== [$(date +%T)] boot $TAG ==="
timeout 120 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -2

echo "=== [$(date +%T)] wait for desktop (poll every 90s, max 12min) ==="
for r in 1 2 3 4 5 6 7 8; do
  sleep 90
  p=$(timeout 6 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  case "$p" in *xnuloader*) ;; *) echo "loader gone at round $r"; break ;; esac
  echo "--- round $r [$(date +%T)] quick frame ---"
  rm -f /mnt/c/ios26/${TAG}-probe.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  get_staged "C:/ios26/${TAG}-probe.raw" >/dev/null 2>&1
  nz=$(python3 -c "d=open('/mnt/c/ios26/${TAG}-probe.raw','rb').read(); print(sum(1 for b in d[::64] if b)*64*100//len(d))" 2>/dev/null || echo 0)
  echo "  nonblack ${nz}%"
  if [ "$nz" -gt 5 ]; then echo "DESKTOP REACHED at round $r"; break; fi
done

grab

echo "=== [$(date +%T)] STM TOUCH STATS ==="
python3 - <<'PY'
import re,os
p='/mnt/c/ios26/s195-log.bin'
if not os.path.exists(p): print('NO LOG'); raise SystemExit
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
print('log bytes',len(d))
for kw in ['GOODIX_INIT_ENTERED','stm: chip id','stm: sense on','stm: system-info',
           'stm: down','stm: move','stm: up','stm: finger','focaltech:','no focaltech',
           'touch screen ready','annibale-touch','input26:']:
    hits=[l.strip() for l in lines if kw in l]
    print('  %-22s %d' % (kw,len(hits)))
    for h in hits[:4]: print('      ',h[:190])
print('--- all stm:/goodix: lines (first 25) ---')
n=0
for l in lines:
    if re.search(r'stm:|goodix:',l):
        print('  ',l.strip()[:190]); n+=1
        if n>=25: break
print('--- counters ---')
for k in ['error=22','PANIC','KERNEL FAULT']:
    print('  %-14s %d' % (k,d.count(k)))
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('  ts', ts[0] if ts else '-', '->', ts[-1] if ts else '-')
PY
echo "=== [$(date +%T)] DONE ==="
