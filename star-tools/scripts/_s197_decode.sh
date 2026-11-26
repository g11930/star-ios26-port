#!/bin/bash
# 抓 stm: poll 的 head 字节，解码成 enter/motion/leave + 坐标
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
rm -f s197dec-*.bin
echo ">>> 请连续滑动 + 点两下 (40 秒)"
for r in $(seq 1 10); do
  timeout 10 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 40 "$F" -s xnuloader get_staged "C:/ios26/s197dec-$r.bin" >/dev/null 2>&1
done
python3 - <<'PY'
import glob,re
poll=[]
for f in sorted(glob.glob('/mnt/c/ios26/s197dec-*.bin'),key=lambda p:int(re.search(r'-(\d+)\.bin',p).group(1))):
    try: d=open(f,'rb').read().decode('utf-8','replace').replace('\0','')
    except Exception: continue
    for l in d.split('\n'):
        m=re.search(r'stm: poll (\d+): head ((?:[0-9a-f]{2} ){7}[0-9a-f]{2}), irq (\d)',l)
        if m and (m.group(1),m.group(2)) not in poll:
            poll.append((m.group(1),m.group(2),m.group(3)))
print('抓到 poll 样本 %d 条' % len(poll))
name={0x13:'ENTER',0x23:'MOVE ',0x33:'LEAVE',0x03:'ready',0x43:'status',0xf3:'error'}
nz=[]
for tick,hx,irq in poll:
    b=[int(x,16) for x in hx.split()]
    if any(b):
        e0=b[0]; x=b[2]|((b[3]&0x0f)<<8); y=(b[4]<<4)|(b[3]>>4)
        nz.append((tick,name.get(e0,'0x%02x'%e0),b[1]>>4,x,y,irq))
print('非零帧 %d 条（说明芯片在报事件）' % len(nz))
for t,k,i,x,y,q in nz[-25:]:
    print('  tick %-7s %s id=%d x=%-5d y=%-5d irq=%s' % (t,k,i,x,y,q))
if not nz: print('  全零 -> 这段时间没有触摸输入到芯片')
PY
