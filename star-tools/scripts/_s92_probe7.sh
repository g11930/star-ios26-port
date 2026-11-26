#!/bin/bash
# 判定：各轮各 pid 的首/末时刻 + error=22 完整时间线
D=/mnt/c/ios26
OUT=$D/probe7.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

for n in 88 89 90 91 92; do
  if [ $n = 92 ]; then f="$D/s92-staged.bin"; else f="$D/s${n}-log.bin"; fi
  [ -f "$f" ] || continue
  e ""
  e "################ s${n}"
  e "--- backboardd 每个 pid 的首/末时刻 ---"
  for pid in $(strings -n 5 "$f" | grep -oE 'backboardd\[[0-9]+' | grep -oE '[0-9]+' | sort -un); do
    first=$(strings -n 5 "$f" | grep -E "backboardd\[$pid:" | grep -oE '2025-12-10 [0-9:.]+' | head -1)
    last=$(strings -n 5 "$f" | grep -E "backboardd\[$pid:" | grep -oE '2025-12-10 [0-9:.]+' | tail -1)
    cnt=$(strings -n 5 "$f" | grep -cE "backboardd\[$pid:")
    e "  pid=$pid  n=$cnt  first=$first  last=$last"
  done
  e "--- SpringBoard 每个 pid 的首/末时刻 ---"
  for pid in $(strings -n 5 "$f" | grep -oE 'SpringBoard\[[0-9]+' | grep -oE '[0-9]+' | sort -un); do
    first=$(strings -n 5 "$f" | grep -E "SpringBoard\[$pid:" | grep -oE '2025-12-10 [0-9:.]+' | head -1)
    last=$(strings -n 5 "$f" | grep -E "SpringBoard\[$pid:" | grep -oE '2025-12-10 [0-9:.]+' | tail -1)
    cnt=$(strings -n 5 "$f" | grep -cE "SpringBoard\[$pid:")
    e "  pid=$pid  n=$cnt  first=$first  last=$last"
  done
  e "--- cs_flags=26000000 全部时刻 ---"
  strings -n 5 "$f" | grep -oE '2025-12-10 [0-9:.]+.*cs_flags=26000000.*' | sed 's/\(.\{110\}\).*/\1/' >> "$OUT"
  e "--- 日志最末时间戳 ---"
  strings -n 5 "$f" | grep -oE '2025-12-10 [0-9]{2}:[0-9]{2}:[0-9]{2}' | sort | tail -1 >> "$OUT"
done

echo OK; ls -l "$OUT"
