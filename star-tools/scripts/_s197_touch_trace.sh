#!/bin/bash
# 连续抓触摸事件：每 4s 抓一次 staged，抽取 stm 事件行，去重后按序输出。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
cd /mnt/c/ios26 || exit 1
rm -f s197touch-*.bin
echo ">>> 现在请在屏幕上滑动/点按 (90 秒窗口)"
for r in $(seq 1 22); do
  timeout 10 "$F" -s xnuloader oem log >/dev/null 2>&1
  timeout 40 "$F" -s xnuloader get_staged "C:/ios26/s197touch-$r.bin" >/dev/null 2>&1
  sleep 1
done
echo "=== 汇总 ==="
python3 - <<'PY'
import glob,re,os
seen=[]
pat=re.compile(r'stm: (down|up|move|finger|poll)')
for f in sorted(glob.glob('/mnt/c/ios26/s197touch-*.bin'),key=lambda p:int(re.search(r'-(\d+)\.bin',p).group(1))):
    try: d=open(f,'rb').read().decode('utf-8','replace').replace('\0','')
    except Exception: continue
    for l in d.split('\n'):
        if pat.search(l):
            s=l.strip()
            if s and s not in seen: seen.append(s)
ev=[s for s in seen if re.search(r'down|up|move|finger',s)]
pol=[s for s in seen if 'poll' in s]
stat=[s for s in seen if 'so far' in s]
print('事件行 %d / poll 行 %d / 统计行 %d' % (len(ev),len(pol),len(stat)))
print('--- 事件 (最多 60 条) ---')
for s in ev[-60:]: print('  ',s[:160])
print('--- 最后一个 poll ---')
for s in pol[-3:]: print('  ',s[:160])
print('--- 最后统计 ---')
for s in stat[-2:]: print('  ',s[:200])
PY
