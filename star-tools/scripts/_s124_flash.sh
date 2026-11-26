#!/bin/bash
# 刷 s124 并验证「launchd 缓存重建 + backboardd delayexec 150」判据
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s124
SLEEP=165
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

echo "=== [$(date +%T)] wait ${SLEEP}s (backboardd is held by delayexec 150) ==="
sleep "$SLEEP"
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

echo "=== [$(date +%T)] analysis ==="
python3 - /mnt/c/ios26/${TAG}-live.bin <<'PY'
import sys, os, re
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LOG"); sys.exit(0)
d=open(p,'rb').read(); t=d.decode('utf-8','replace').replace('\0','')
print("size",len(d))
pats=["delayexec: sleeping","annibale lib loaded","start HID system","start GS",
      "start window server","Initializing CAWindowServer","window server hooks",
      "P28FAULT","Received handshake request from","Removing all cached process handles",
      "IOSvcOpen","triald[","disp0"]
for x in pats: print("  %-42s %d"%(x,t.count(x)))
ts=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',t)
print("  time:",ts[0] if ts else "?","->",ts[-1] if ts else "?")
for l in t.split('\n'):
    if any(k in l for k in ('delayexec:','start HID','start GS','start window','CAWindowServer','handshake request from','annibale lib loaded')):
        print("   ",l[:190])
PY
echo "=== [$(date +%T)] DONE"
