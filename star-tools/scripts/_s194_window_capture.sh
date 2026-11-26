#!/bin/bash
# Loader reboots in cycles: gone at 2-6s, back at 8-14s. Capture in that window.
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
cd /mnt/c/ios26 || exit 1
echo "=== to ABL + boot ==="
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) break;; esac; done
timeout 120 "$F" boot C:/ios26/s194-boot.img 2>&1 | tr -d '\r' | tail -1
echo "=== tight capture loop ==="
# capture continuously: whenever loader responds, oem log + get_staged
for r in $(seq 1 60); do
  p=$(timeout 3 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  if [[ "$p" == *xnuloader* ]]; then
    echo "  r$r [$(date +%T)] loader UP -> oem log + get_staged"
    timeout 10 "$F" -s xnuloader oem log >/dev/null 2>&1
    rm -f /mnt/c/ios26/s194-win-$r.bin
    timeout 12 "$F" -s xnuloader get_staged "C:/ios26/s194-win-$r.bin" >/dev/null 2>&1
    sz=$(stat -c %s /mnt/c/ios26/s194-win-$r.bin 2>/dev/null || echo 0)
    echo "     staged=$sz"
    if [ "$sz" -gt 50000 ]; then echo "     GOT IT r$r"; echo $r > /tmp/win_round; break; fi
  else
    echo -n "."
  fi
  sleep 1
done
echo
echo "=== analyze ==="
python3 - <<'PY'
import glob,os,re
fs=sorted(glob.glob('/mnt/c/ios26/s194-win-*.bin'),key=os.path.getmtime)
fs=[f for f in fs if os.path.getsize(f)>50000]
if not fs: print('NO GOOD CAPTURE'); raise SystemExit
p=fs[-1]; d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
print('FILE',os.path.basename(p),len(d))
for kw in ['GOODIX_INIT_ENTERED','stm:','goodix:','panic','PANIC','kalloc_type_view','data abort','ESR','backtrace','Kernel fault','KERNEL FAULT','fault','abort','fatal']:
    print('  %-22s %d' % (kw,d.count(kw)))
lines=d.split('\n')
for m in re.finditer(r'panic|data abort|KERNEL FAULT|kalloc_type_view|fault',d,re.I):
    print('--- CTX ---'); print(d[max(0,m.start()-200):m.start()+500].replace('\n',' | ')[:650]); break
print('--- last 15 ---')
for l in [x for x in lines if x.strip()][-15:]: print('  ',l.strip()[:180])
PY
