#!/bin/bash
# 最后拼图：SpringBoard 崩溃前上下文 + sbmetal26 垫片源码 + s91 首次 error=22 前后
D=/mnt/c/ios26
OUT=$D/probe8.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) s91: SpringBoard[33] 全部行（它只活 4 秒）"
strings -n 5 "$D/s91-log.bin" | grep -E "^2025.*SpringBoard\[33:" >> "$OUT"
e ""
e "############ 2) s91: 03:03:53.0 .. 03:03:56.0 全进程时间窗（崩溃现场）"
strings -n 5 "$D/s91-log.bin" | grep -E "^2025-12-10 03:03:5[3-5]" | head -120 >> "$OUT"
e ""
e "############ 3) s90 对照：同一时间窗 03:03:53 .. 03:03:56"
strings -n 5 "$D/s90-log.bin" | grep -E "^2025-12-10 03:03:5[3-5]" | head -60 >> "$OUT"

e ""
e "############ 4) sbmetal26 垫片源码位置"
grep -rln "sbmetal26" /root/star26/ 2>/dev/null | head -20 >> "$OUT"

e ""
e "############ 5) star_sbmetal boot-arg 解析处"
grep -rn "star_sbmetal" /root/star26/star-native/ 2>/dev/null | head -10 >> "$OUT"

echo OK; ls -l "$OUT"
