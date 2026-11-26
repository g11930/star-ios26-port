#!/bin/bash
# 每 60s 抓一次 staged，报告触摸统计行，直到进桌面或 9 分钟超时。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
T0=$(date +%s)
el () { echo $(( $(date +%s) - T0 )); }
for r in $(seq 1 10); do
  sleep 50
  p=$(timeout 4 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
  if [[ "$p" != *xnuloader* ]]; then echo "[$(el)s] loader gone (round $r)"; break; fi
  timeout 15 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f /mnt/c/ios26/s197mon-$r.bin
  timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s197mon-$r.bin" >/dev/null 2>&1
  sz=$(stat -c %s /mnt/c/ios26/s197mon-$r.bin 2>/dev/null || echo 0)
  python3 - "$r" "$sz" <<'PY'
import sys,re
r,sz=sys.argv[1],sys.argv[2]
try:
    d=open('/mnt/c/ios26/s197mon-%s.bin'%r,'rb').read().decode('utf-8','replace').replace('\0','')
except Exception:
    print('  r%s no file'%r); raise SystemExit
stat=[l.strip() for l in d.split('\n') if 'so far' in l]
down=[l.strip() for l in d.split('\n') if re.search(r'stm: (down|up|move|finger)',l)]
ready='stm touch screen ready' in d
print('  r%s %sB ready=%s touchstat=%d events=%d' % (r,sz,ready,len(stat),len(down)))
if stat: print('     ',stat[-1][:200])
if down: print('      last event:',down[-1][:120])
PY
done
echo "=== [$(el)s] screenshot ==="
timeout 20 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
rm -f /mnt/c/ios26/s197mon-frame.raw
timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s197mon-frame.raw" >/dev/null 2>&1
ls -l /mnt/c/ios26/s197mon-frame.raw 2>/dev/null
cd /mnt/d/桌面/star26-deps/scripts && python3 raw2png.py /mnt/c/ios26/s197mon-frame.raw 2>&1 | tail -3
echo "=== [$(el)s] DONE ==="
