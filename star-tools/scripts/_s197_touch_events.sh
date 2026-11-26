#!/bin/bash
# 正确过滤：stm: event / down / move / up + 统计行里的 finger positions
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
rm -f s197ev-*.bin
echo ">>> 现在请滑动、点按、再松手 (60 秒)"
for r in $(seq 1 16); do
  timeout 10 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 40 "$F" -s xnuloader get_staged "C:/ios26/s197ev-$r.bin" >/dev/null 2>&1
  sleep 1
done
python3 - <<'PY'
import glob,re
seen=[]
for f in sorted(glob.glob('/mnt/c/ios26/s197ev-*.bin'),key=lambda p:int(re.search(r'-(\d+)\.bin',p).group(1))):
    try: d=open(f,'rb').read().decode('utf-8','replace').replace('\0','')
    except Exception: continue
    for l in d.split('\n'):
        if re.search(r'stm: (event|down|move|up)|stm: so far|stm: poll',l):
            s=l.strip()
            if s and s not in seen: seen.append(s)
ev=[s for s in seen if re.search(r'stm: (event|down|move|up)',s)]
print('驱动事件行 %d' % len(ev))
for s in ev[-45:]: print('  ',s[:150])
st=[s for s in seen if 'so far' in s]
print('--- 统计行 (末 3) ---')
for s in st[-3:]: print('  ',s[:210])
PY
