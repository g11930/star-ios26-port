#!/bin/bash
# s200 快速盯盘：每 7 秒抓一次，只把匹配行追加到 s200watch.txt（不受环形缓冲冲掉影响）。
# 匹配：tl: s（swap 交进内核）、tl: v（presenter 画完）、fb_diff 的每帧变化像素、frames-in 统计。
set -u
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
OUT=/mnt/c/ios26
LOG=$OUT/s200watch.txt
: > "$LOG"
N=${1:-40}
echo ">>> s200 fast watch start $(date +%H:%M:%S)  rounds=$N"
for r in $(seq 1 "$N"); do
  T=$(date +%H:%M:%S)
  timeout 12 "$F" -s xnuloader oem log >/dev/null 2>&1
  rm -f "$OUT/s200w.bin"
  timeout 45 "$F" -s xnuloader get_staged "C:/ios26/s200w.bin" >/dev/null 2>&1
  python3 - "$OUT/s200w.bin" "$T" "$LOG" >> "$LOG" <<'PY'
import sys
p, t, logp = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = open(p, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
except Exception:
    print('%s  (no snapshot)' % t); raise SystemExit
seen = set()
try:
    for l in open(logp, 'r', errors='replace').read().split('\n')[-900:]:
        seen.add(l.strip())
except Exception:
    pass
keep = []
for l in d.split('\n'):
    s = l.strip()
    if not s:
        continue
    if ('tl: s ' in s or 'tl: v ' in s or 'tl: w ' in s
            or 'pixels of the panel changed a frame' in s
            or ('frames in ' in s and 'MiniIOMobileFramebuffer' in s)
            or s.startswith('P34:')):
        s = s[:260]
        if s in seen:
            continue
        seen.add(s)
        keep.append(s)
if keep:
    print('--- %s ---' % t)
    for s in keep:
        print('  ' + s)
PY
  sleep 7
done
echo ">>> s200 fast watch done $(date +%H:%M:%S)"
