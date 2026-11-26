#!/bin/bash
# s196 原图复现 + 密集窗口抓取（不改镜像，单变量=只改抓取方式）
# 目标：拿到 12s 延迟线程启动后、16.8s 崩溃前的那几行最后输出。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
IMG=/mnt/c/ios26/s197-boot.img
WIMG=C:/ios26/s197-boot.img
cd /mnt/c/ios26 || exit 1
T0=$(date +%s)
el () { echo $(( $(date +%s) - T0 )); }

echo "=== [$(el)s] preflight ==="
"$A" start-server >/dev/null 2>&1
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in
  *xnuloader*) echo "in loader -> reboot"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 12 ;;
esac
p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
case "$p" in *star*) ;; *)
  "$A" reboot bootloader >/dev/null 2>&1
  for i in $(seq 1 40); do sleep 2; p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1); case "$p" in *star*) break;; esac; done ;;
esac
echo "ABL: $p"
[ -z "$p" ] && { echo ABORT-no-ABL; exit 3; }

echo "=== [$(el)s] boot s197 ==="
timeout 120 "$F" boot "$WIMG" 2>&1 | tr -d '\r' | tail -2
echo "=== [$(el)s] boot returned, tight capture ==="

miss=0
for r in $(seq 1 40); do
  p=$(timeout 3 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  if [[ "$p" == *xnuloader* ]]; then
    miss=0
    timeout 10 "$F" -s xnuloader oem log >/dev/null 2>&1
    rm -f /mnt/c/ios26/s197win-$r.bin
    timeout 15 "$F" -s xnuloader get_staged "C:/ios26/s197win-$r.bin" >/dev/null 2>&1
    sz=$(stat -c %s /mnt/c/ios26/s197win-$r.bin 2>/dev/null || echo 0)
    last=$(python3 -c "
import sys
try:
    d=open('/mnt/c/ios26/s197win-$r.bin','rb').read().decode('utf-8','replace').replace('\0','')
    ls=[l.strip() for l in d.split('\n') if l.strip()]
    print(ls[-1][:110] if ls else '-')
except Exception as e: print('-')
" 2>/dev/null)
    echo "[$(el)s] r$r staged=$sz last=$last"
  else
    miss=$((miss+1)); echo -n "."
    if [ "$miss" -ge 4 ]; then echo " [$(el)s] loader gone x4 -> stop"; break; fi
  fi
  sleep 1
done

echo
echo "=== [$(el)s] analyze ==="
python3 - <<'PY'
import glob,os,re
fs=sorted(glob.glob('/mnt/c/ios26/s197win-*.bin'),key=os.path.getmtime)
fs=[f for f in fs if os.path.getsize(f)>3000]
if not fs: print('NO CAPTURE'); raise SystemExit
p=fs[-1]; d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
print('FILE',os.path.basename(p),len(d),'snapshots',len(fs))
lines=[l.rstrip() for l in d.split('\n')]
g=[(i,l) for i,l in enumerate(lines) if re.search(r'goodix:|stm:',l)]
print('goodix lines',len(g))
print('--- last 22 goodix ---')
for i,l in g[-22:]: print(' ',l.strip()[:185])
print('--- lines after last goodix ---')
if g:
    for l in [x for x in lines[g[-1][0]:g[-1][0]+18] if x.strip()]: print('   ',l.strip()[:175])
for kw in ['panic','PANIC','data abort','KERNEL FAULT','kalloc_type_view','ESR','backtrace','ignite(','File system','preboot']:
    c=d.count(kw)
    if c: print('  %-20s %d' % (kw,c))
PY
echo "=== [$(el)s] DONE ==="
