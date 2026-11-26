#!/bin/bash
# s90 屏幕取证 + 活日志抓取。顺序：先截图(覆盖staged) -> 转PNG；再 oem log -> 取日志。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] device check ==="
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1
timeout 8 "$F" getvar result 2>&1 | tr -d '\r' | grep -i result: | head -1

echo "=== [$(date +%T)] STEP 1: oem screenshot -> frame.raw ==="
rm -f /mnt/c/ios26/s90-frame.raw /mnt/c/ios26/s90-frame.png
timeout 40 "$F" -s xnuloader oem screenshot 2>&1 | tr -d '\r' | tail -3
for try in 1 2 3; do
	timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s90-frame.raw" 2>&1 | tr -d '\r' | tail -2
	if [ -s /mnt/c/ios26/s90-frame.raw ]; then echo "frame: $(stat -c %s /mnt/c/ios26/s90-frame.raw) bytes"; break; fi
	sleep 2
done

echo "=== [$(date +%T)] STEP 2: frame -> PNG ==="
if [ -s /mnt/c/ios26/s90-frame.raw ]; then
	python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s90-frame.raw /mnt/c/ios26/s90-frame.png 2>&1
	ls -la /mnt/c/ios26/s90-frame.png
else
	echo "NO FRAME CAPTURED"
fi

echo "=== [$(date +%T)] STEP 3: oem log -> s90-live.bin ==="
rm -f /mnt/c/ios26/s90-live.bin
timeout 40 "$F" -s xnuloader oem log 2>&1 | tr -d '\r' | tail -3
for try in 1 2 3; do
	timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s90-live.bin" 2>&1 | tr -d '\r' | tail -2
	if [ -s /mnt/c/ios26/s90-live.bin ]; then echo "log: $(stat -c %s /mnt/c/ios26/s90-live.bin) bytes"; break; fi
	sleep 2
done

echo "=== [$(date +%T)] STEP 4: analyze live log ==="
python3 - /mnt/c/ios26/s90-live.bin <<'PY'
import sys, os
p=sys.argv[1]
if not os.path.exists(p) or os.path.getsize(p)==0:
    print("NO LIVE LOG"); sys.exit(0)
d=open(p,'rb').read()
t=d.decode('utf-8','replace').replace('\0','')
print("size",len(d),"text",len(t))
pats=["== KERNEL LOG ==","== XNULOADER","error=22","cs_flags=26000000","NOT_CODESIGNED",
      "SecTaskLoadEntitlements","acquired main display digitizer","registration completed",
      "SpringBoard","backboardd","P28EXIT","NOT_CODESIGNED","Handshake succeeded",
      "default_before","AnnibaleMetal","MTLDevice","STARX","spawn","launchd"]
for x in pats:
    print("  %-38s %d"%(x,t.count(x)))
print("=== error=22 contexts ===")
i=0
while True:
    i=t.find("error=22",i)
    if i<0: break
    print("  ...",t[max(0,i-100):i+100].replace("\n"," "))
    i+=8
print("=== digitizer contexts ===")
i=0
while True:
    i=t.find("digitizer",i)
    if i<0: break
    print("  ...",t[max(0,i-80):i+80].replace("\n"," "))
    i+=9
PY
echo "=== [$(date +%T)] DONE"
