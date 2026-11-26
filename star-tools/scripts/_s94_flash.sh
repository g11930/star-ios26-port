#!/bin/bash
# 刷 s94 = s90 基线 + CS_VALID 守卫补丁。boot 后抓活日志验证判据。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
TAG=s94
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] preflight ==="
"$A" start-server >/dev/null 2>&1
sleep 1
ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
echo "android devices = $ad"
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "fastboot product = ${p:-none}"
case "$p" in
  *xnuloader*) echo "in loader: rebooting out"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 4 ;;
esac
if [ "$ad" -lt 1 ]; then
  # try to recover android
  for i in $(seq 1 20); do
    sleep 2
    ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
    [ "$ad" -gt 0 ] && { echo "android recovered at try $i"; break; }
  done
fi
[ "$ad" -lt 1 ] && { echo "ABORT: no android device"; exit 2; }

echo "=== [$(date +%T)] reboot bootloader ==="
"$A" reboot bootloader >/dev/null 2>&1
ok=0
for i in $(seq 1 40); do
  sleep 2
  p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  case "$p" in *star*) echo "ABL fastboot: $p (try $i)"; ok=1; break ;; esac
  if [ $((i % 10)) -eq 0 ]; then echo "  waiting fastboot... prod='${p:-none}'"; fi
done
[ "$ok" != "1" ] && { echo "ABORT: no ABL fastboot"; exit 3; }

echo "=== [$(date +%T)] boot ${TAG}-boot.img ($(stat -c %s /mnt/c/ios26/${TAG}-boot.img) bytes) ==="
timeout 200 "$F" boot "C:/ios26/${TAG}-boot.img" 2>&1 | tr -d '\r' | tail -5

echo "=== [$(date +%T)] wait 35s for kernel to advance ==="
sleep 35
timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i result: | head -1 || true
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1 || true

echo "=== [$(date +%T)] grab live log (oem log -> get_staged) ==="
rm -f /mnt/c/ios26/${TAG}-live.bin
timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2
for try in 1 2 3; do
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/${TAG}-live.bin" 2>&1 | tr -d '\r' | tail -2
  [ -s /mnt/c/ios26/${TAG}-live.bin ] && { echo "captured $(stat -c %s /mnt/c/ios26/${TAG}-live.bin) bytes"; break; }
  sleep 2
done

echo "=== [$(date +%T)] analysis ==="
python3 - /mnt/c/ios26/${TAG}-live.bin <<'PY'
import sys, os, re, collections
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LIVE LOG"); sys.exit(0)
d=open(p,'rb').read(); t=d.decode('utf-8','replace').replace('\0','')
print("size",len(d))
pats=["error=22","cs_flags=26000000","NOT_CODESIGNED","SecTaskLoadEntitlements",
      "acquired main display digitizer","lost main display digitizer","registration completed",
      "first_frame","WindowServer","swap","commit","SpringBoard[","backboardd[",
      "P28EXIT","sb26:","build=23G90"]
for x in pats: print("  %-38s %d"%(x,t.count(x)))
# distinct SpringBoard pids
pids=set()
for m in re.finditer(r'SpringBoard\[(\d+)',t): pids.add(m.group(1))
print("  SpringBoard distinct PIDs:",sorted(pids,key=lambda x:int(x)))
print("  error=22 contexts:")
i=0
while True:
    i=t.find("error=22",i)
    if i<0: break
    print("   ...",t[max(0,i-80):i+80].replace("\n"," ")); i+=8
PY
echo "=== [$(date +%T)] DONE"
