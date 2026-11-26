#!/bin/bash
# 后台 90s 窗口：连续抓 staged，解出所有非零触摸帧；最后截一张图
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
rm -f s197sw-*.bin
echo ">>> 120 秒窗口开启 ($(date +%T))"
for r in $(seq 1 22); do
  timeout 8 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 30 "$F" -s xnuloader get_staged "C:/ios26/s197sw-$r.bin" >/dev/null 2>&1
  sleep 5
done
echo "=== 解码 ==="
python3 - <<'PY'
import glob,re
rows=[]
for f in sorted(glob.glob('/mnt/c/ios26/s197sw-*.bin'),key=lambda p:int(re.search(r'-(\d+)\.bin',p).group(1))):
    try: d=open(f,'rb').read().decode('utf-8','replace').replace('\0','')
    except Exception: continue
    for l in d.split('\n'):
        m=re.search(r'stm: poll (\d+): head ((?:[0-9a-f]{2} ){7}[0-9a-f]{2}), irq (\d)',l)
        if m:
            t,h,q=m.groups()
            b=[int(x,16) for x in h.split()]
            if any(b): rows.append((int(t),b,q))
rows=sorted(set(rows))
name={0x13:'ENTER',0x23:'MOVE ',0x33:'LEAVE',0x03:'ready',0x43:'status',0xf3:'error'}
print('活动帧 %d 条'%len(rows))
for t,b,q in rows[-30:]:
    print('  tick %-7d %s id=%d x=%-5d y=%-5d irq=%s'%(t,name.get(b[0],hex(b[0])),b[1]>>4,b[2]|((b[3]&0xf)<<8),(b[4]<<4)|(b[3]>>4),q))
PY
echo "=== 截图 ==="
timeout 20 "$F" -s xnuloader oem screenshot >/dev/null 2>&1
rm -f s197sw.raw; timeout 60 "$F" -s xnuloader get_staged "C:/ios26/s197sw.raw" >/dev/null 2>&1
cd /mnt/d/桌面/star26-deps/scripts && python3 raw2png.py /mnt/c/ios26/s197sw.raw 2>&1 | tail -1
echo "=== DONE ==="
