#!/bin/bash
# 决定性判定：s90 是"没崩"还是"日志短"？统计各轮 backboardd/SpringBoard 的 pid 集合 + 首末时刻
D=/mnt/c/ios26
OUT=$D/probe6.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

for n in 89 90 91 92; do
  if [ $n = 92 ]; then f="$D/s92-staged.bin"; else f="$D/s${n}-log.bin"; fi
  e ""
  e "################ s${n}  ($(basename $f), $(stat -c%s $f) B)"
  e "--- 首/末 时间戳 ---"
  strings -n 5 "$f" | grep -oE '2025-12-10 [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+' | sort | head -1 >> "$OUT"
  strings -n 5 "$f" | grep -oE '2025-12-10 [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+' | sort | tail -1 >> "$OUT"
  e "--- backboardd 出现过的 pid 集合 ---"
  strings -n 5 "$f" | grep -oE 'backboardd\[[0-9]+:' | sort -u -t'[' -k2 -n | tr '\n' ' ' >> "$OUT"; e ""
  e "--- SpringBoard 出现过的 pid 集合 ---"
  strings -n 5 "$f" | grep -oE 'SpringBoard\[[0-9]+:' | sort -u -t'[' -k2 -n | tr '\n' ' ' >> "$OUT"; e ""
  e "--- launchd 出现过的 pid 集合 ---"
  strings -n 5 "$f" | grep -oE '(launchd|init)\[[0-9]+:' | sort -u -t'[' -k2 -n | tr '\n' ' ' >> "$OUT"; e ""
  e "--- 最后 20 行（原样） ---"
  strings -n 5 "$f" | tail -20 >> "$OUT"
done

echo OK; ls -l "$OUT"
