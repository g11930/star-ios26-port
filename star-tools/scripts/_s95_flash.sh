#!/bin/bash
# 刷 s95 并验证第一步修复（无条件 plugin 属性）判据
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s95
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1
sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
echo "android devices = $ad"
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in
  *xnuloader*) echo "in loader: rebooting out"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 4 ;;
esac
echo "=== [$(date +%T)] ensure ABL fastboot ==="
ok=0
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) echo "already ABL fastboot: $p"; ok=1 ;; esac
if [ "$ok" != "1" ]; then
  [ "$ad" -lt 1 ] && { echo "ABORT: no android and no fastboot"; exit 2; }
  echo "rebooting android -> bootloader"
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do
    sleep 2
    p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
    case "$p" in *star*) echo "ABL fastboot: $p (try $i)"; ok=1; break ;; esac
  done
fi
[ "$ok" != "1" ] && { echo "ABORT: no ABL fastboot"; exit 3; }

echo "=== [$(date +%T)] boot ${TAG}-boot.img ($(stat -c %s ${TAG}-boot.img) bytes) ==="
timeout 200 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -5

echo "=== [$(date +%T)] wait 95s to reach userspace Metal registration ==="
sleep 95
timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i result: | head -1 || true
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1 || true

echo "=== [$(date +%T)] grab live log ==="
rm -f /mnt/c/ios26/${TAG}-live.bin
timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2
for try in 1 2 3; do
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}-live.bin" 2>&1 | tr -d '\r' | tail -2
  [ -s /mnt/c/ios26/${TAG}-live.bin ] && { echo "log $(stat -c %s /mnt/c/ios26/${TAG}-live.bin) bytes"; break; }
  sleep 2
done

echo "=== [$(date +%T)] screenshot ==="
rm -f /mnt/c/ios26/${TAG}-frame.raw /mnt/c/ios26/${TAG}-frame.png
timeout 40 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -2
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}-frame.raw" 2>&1 | tr -d '\r' | tail -2
if [ -s /mnt/c/ios26/${TAG}-frame.raw ]; then
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/${TAG}-frame.raw /mnt/c/ios26/${TAG}-frame.png 2>&1
fi

echo "=== [$(date +%T)] analysis: step1 judgement ==="
python3 - /mnt/c/ios26/${TAG}-live.bin <<'PY'
import sys, os, re
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LOG"); sys.exit(0)
d=open(p,'rb').read(); t=d.decode('utf-8','replace').replace('\0','')
print("size",len(d))
pats=["error=22","cs_flags=26000000","NOT_CODESIGNED",
      "IOAcceleratorES unavailable","registration device=0","registration device=1",
      "default_before","adopted native default","AnnibaleMetal","MTLDevice",
      "WindowServer","first_frame","swap","commit","SpringBoard[","backboardd[",
      "acquired main display digitizer","sb26:","P28EXIT"]
for x in pats: print("  %-38s %d"%(x,t.count(x)))
ids=set()
for m in re.finditer(r'SpringBoard\[(\d+)',t): ids.add(m.group(1))
print("  SpringBoard PIDs:",sorted(ids,key=lambda x:int(x)))
ts=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',t)
print("  time:",ts[0] if ts else "?","->",ts[-1] if ts else "?")
print("--- registration lines ---")
for l in t.split('\n'):
    if 'registration device' in l or 'default_before' in l or 'IOAcceleratorES' in l:
        print("   ",l[:180])
PY
echo "=== [$(date +%T)] DONE"
