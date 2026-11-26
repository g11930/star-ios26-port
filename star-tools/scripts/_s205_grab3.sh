#!/bin/bash
# 第三次抓取：看 swap 计数是否继续增长（判断渲染是否活着）。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
timeout 20 "$F" -s xnuloader oem log >/dev/null 2>&1
timeout 60 "$F" -s xnuloader get_staged C:/ios26/s205b-3.bin >/dev/null 2>&1
python3 - <<'PY'
import re
d = open('/mnt/c/ios26/s205b-3.bin','rb').read().decode('utf-8','replace').replace('\0','')
ts = re.findall(r'2025-\d\d-\d\d \d\d:\d\d:\d\d', d)
print('last_ts=%s' % (ts[-1] if ts else '-'))
print('P34 panel swap:', re.findall(r'P34: panel swap (\d+)', d))
print('frames:', re.findall(r'MiniIOMobileFramebuffer: (\d+) frames in (\d+) ms \((\d+) a second\), (\d+) us each', d))
print('gaps:', [m[:180] for m in re.findall(r'[^\n]*from one frame to the next[^\n]*', d)])
# 解锁后的关键事件
for m in re.findall(r'[^\n]*(unlocked|Setup|setup assistant|activation)[^\n]*', d)[-8:]:
    print('EV:', m[:150])
# 最近 20 行
lines = [l for l in d.split('\n') if l.strip()]
for l in lines[-15:]:
    print('TL:', l[:140])
PY
