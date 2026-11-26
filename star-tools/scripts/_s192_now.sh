#!/bin/bash
# grab current state of running s192 + convert, wait if still Apple logo
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
p=$(timeout 8 "$F" -s xnuloader getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
echo "loader: $p"
case "$p" in *xnuloader*) ;; *) echo "loader gone"; exit 1 ;; esac
for round in 1 2 3; do
  echo "=== round $round [$(date +%T)] ==="
  rm -f /mnt/c/ios26/s192now-log.bin
  timeout 30 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s192now-log.bin" 2>&1 | tr -d '\r' | tail -1
  rm -f /mnt/c/ios26/s192now-frame.raw
  timeout 30 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s192now-frame.raw" 2>&1 | tr -d '\r' | tail -1
  cd /mnt/d/桌面/star26-deps/scripts
  python3 raw2png.py /mnt/c/ios26/s192now-frame.raw 2>&1 | grep -E "not black" | head -1
  python3 - /mnt/c/ios26/s192now-log.bin <<'PY'
import sys,re
d=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('  last ts', ts[-1] if ts else '-')
print('  iconfill fire lines:', len(re.findall(r'iconfill fire',d)))
print('  iconfill pass enter:', len(re.findall(r'iconfill pass enter',d)))
print('  iconfill filled   :', len(re.findall(r'iconfill: filled',d)))
PY
  # check if desktop reached (nonblack > 5%) or time advanced a lot
  nz=$(python3 -c "d=open('/mnt/c/ios26/s192now-frame.raw','rb').read(); print(sum(1 for b in d[::64] if b)*64*100//len(d))")
  echo "  nonblack approx ${nz}%"
  if [ "$nz" -gt 5 ]; then echo "  DESKTOP REACHED"; break; fi
  echo "  still booting, sleep 120"; sleep 120
done
