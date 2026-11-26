#!/bin/bash
# 取证5：日志时间线 / 环形缓冲判定 / sbmetal 垫片源码
D=/mnt/c/ios26
SRC=/root/star26/star-native
OUT=$D/probe5.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

for n in 90 91 92; do
  f=$( [ $n = 92 ] && echo "$D/s92-staged.bin" || echo "$D/s${n}-log.bin" )
  e ""
  e "################ s${n} timeline ($(basename $f))"
  e "--- 第一条/最后一条带时间戳的行 ---"
  strings -n 5 "$f" | grep -oE '^2025-[0-9:.+-]+' | head -1 >> "$OUT"
  strings -n 5 "$f" | grep -oE '^2025-[0-9:.+-]+' | tail -1 >> "$OUT"
  e "--- 时间戳总行数 ---"
  strings -n 5 "$f" | grep -cE '^2025-' >> "$OUT"
  e "--- 关键进程行（带时间戳，前 25） ---"
  strings -n 5 "$f" | grep -E '^2025-' | grep -E 'SpringBoard|backboardd|launchd|runningboardd' | head -25 >> "$OUT"
  e "--- 是否有截断/环标记 ---"
  strings -n 5 "$f" | grep -inE 'truncat|ring|wrap|overflow|dropped|log_full' | head -10 >> "$OUT"
done

e ""
e "############ sbmetal 垫片全部出现行（s90 vs s91）"
for n in 90 91; do
  e "--- s$n ---"
  strings -n 5 "$D/s${n}-log.bin" | grep -n "sbmetal26" >> "$OUT"
done

e ""
e "############ sbmetal 垫片源码位置"
grep -rln "sbmetal26" /root/star26/hackios-xnu-userland/ /root/star26/star-native/ 2>/dev/null | head -20 >> "$OUT"

echo OK; ls -l "$OUT"
