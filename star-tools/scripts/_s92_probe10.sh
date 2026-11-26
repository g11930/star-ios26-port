#!/bin/bash
# 关键验证：STARX 通道是否存在 / s92 cmdline 是否生效 / SpringBoard 死因
D=/mnt/c/ios26
OUT=$D/probe10.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) 各轮 STARX 命中数 + 样例"
for n in 90 91; do
  e "--- s$n ---"
  e "count=$(strings -n 5 $D/s${n}-log.bin | grep -c STARX)"
  strings -n 5 "$D/s${n}-log.bin" | grep -m 5 "STARX" >> "$OUT"
done
e "--- s92 ---"
e "count=$(strings -n 5 $D/s92-staged.bin | grep -c STARX)"
strings -n 5 "$D/s92-staged.bin" | grep -m 5 "STARX" >> "$OUT"

e ""
e "############ 2) 各轮日志里 cmdline 实际生效行"
for n in 90; do
  strings -n 5 "$D/s${n}-log.bin" | grep -m 2 "^cmdline:" | sed 's/\(.\{500\}\).*/\1/' >> "$OUT"
done
strings -n 5 "$D/s92-staged.bin" | grep -m 2 "^cmdline:" | sed 's/\(.\{500\}\).*/\1/' >> "$OUT"

e ""
e "############ 3) star_trace 相关：STARX 前缀定义处 + 是否有 boot-arg 开关"
grep -rn "STARX" /root/star26/star-native/ --include=*.c --include=*.h 2>/dev/null | head -10 >> "$OUT"

e ""
e "############ 4) s91: SpringBoard 崩溃/退出证据（找 crash/exit/kill/assert）"
strings -n 5 "$D/s91-log.bin" | grep -iE "SpringBoard|backboardd" | grep -iE "crash|exit|kill|abort|assert|signal|SIGTRAP|SIGABRT|terminat|RBS.*(kill|death)|unsatisfied" | head -40 >> "$OUT"

e ""
e "############ 5) s91: 03:03:54.1 .. 03:03:56 里 SpringBoard/backboardd 最后一刻"
strings -n 5 "$D/s91-log.bin" | grep -E "^2025-12-10 03:03:5[4-6]" | grep -E "SpringBoard|backboardd|Metal|terminat|kill|assert|exit" | head -40 >> "$OUT"

e ""
e "############ 6) s90 vs s91: Metal / MTLCreateSystemDefaultDevice / 断言 相关"
for n in 90 91; do
  e "--- s$n ---"
  strings -n 5 "$D/s${n}-log.bin" | grep -iE "MTLCreate|MetalDevice|MetalPlugin|Assertion failed|conformsToProtocol|MTLDeviceSPI|softpipe|AnnibaleMetal" | head -20 >> "$OUT"
done

echo OK; ls -l "$OUT"
