#!/bin/bash
# s94 二次抓日志：再等 60s 让系统推进到用户态，抓成熟日志验证判据
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] current state ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1
timeout 8 "$F" getvar result 2>&1 | tr -d '\r' | grep -i result: | head -1

echo "=== [$(date +%T)] wait 60s more ==="
sleep 60

echo "=== [$(date +%T)] grab mature live log ==="
rm -f /mnt/c/ios26/s94-live2.bin
timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -2
for try in 1 2 3; do
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s94-live2.bin" 2>&1 | tr -d '\r' | tail -2
  [ -s /mnt/c/ios26/s94-live2.bin ] && { echo "captured $(stat -c %s /mnt/c/ios26/s94-live2.bin) bytes"; break; }
  sleep 2
done

echo "=== [$(date +%T)] screenshot ==="
rm -f /mnt/c/ios26/s94-frame.raw /mnt/c/ios26/s94-frame.png
timeout 40 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -2
timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s94-frame.raw" 2>&1 | tr -d '\r' | tail -2
if [ -s /mnt/c/ios26/s94-frame.raw ]; then
  python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s94-frame.raw /mnt/c/ios26/s94-frame.png 2>&1
  stat -c 'frame %s bytes' /mnt/c/ios26/s94-frame.png
fi

echo "=== [$(date +%T)] analysis ==="
python3 - /mnt/c/ios26/s94-live2.bin <<'PY'
import sys, os, re
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LOG"); sys.exit(0)
d=open(p,'rb').read(); t=d.decode('utf-8','replace').replace('\0','')
print("size",len(d))
pats=["error=22","cs_flags=26000000","NOT_CODESIGNED","SecTaskLoadEntitlements",
      "acquired main display digitizer","lost main display digitizer","registration completed",
      "first_frame","WindowServer","swap","commit","SpringBoard[","backboardd[",
      "P28EXIT","sb26:","activation_installed","default_before"]
for x in pats: print("  %-38s %d"%(x,t.count(x)))
pids=set()
for m in re.finditer(r'SpringBoard\[(\d+)',t): pids.add(m.group(1))
bps=set()
for m in re.finditer(r'backboardd\[(\d+)',t): bps.add(m.group(1))
print("  SpringBoard PIDs:",sorted(pids,key=lambda x:int(x)))
print("  backboardd PIDs:",sorted(bps,key=lambda x:int(x)))
print("--- sb26 lines ---")
for l in t.split('\n'):
    if 'sb26:' in l: print("  ",l[:180])
print("--- error=22 contexts ---")
i=0
while True:
    i=t.find("error=22",i)
    if i<0: break
    print("   ...",t[max(0,i-90):i+90].replace("\n"," ")); i+=8
print("--- last timestamp ---")
ts=re.findall(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d',t)
print("  ",ts[-1] if ts else "none")
PY
echo "=== [$(date +%T)] DONE"
