#!/bin/bash
# 终局验证：s90 SB 完整轨迹 / s92 的 STARX 探针输出 / s90 backboardd 是否也走到 runningboard
D=/mnt/c/ios26
OUT=$D/probe9.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) s90: SpringBoard[32] 全部行"
strings -n 5 "$D/s90-log.bin" | grep -E "SpringBoard\[32:" >> "$OUT"

e ""
e "############ 2) s90: backboardd[39] 里所有 [connection]/[Common] 业务行"
strings -n 5 "$D/s90-log.bin" | grep -E "backboardd\[39:" | grep -E "\[connection\]|\[Common\]|handshake|runningboard|IOService|Metal|IOAccelerator" | head -60 >> "$OUT"

e ""
e "############ 3) s91: backboardd[39] 同样过滤（对照）"
strings -n 5 "$D/s91-log.bin" | grep -E "backboardd\[39:" | grep -E "\[connection\]|\[Common\]|handshake|runningboard|IOService|Metal|IOAccelerator" | head -60 >> "$OUT"

e ""
e "############ 4) s92: STARX 探针输出（star_trace 通道）"
strings -n 5 "$D/s92-staged.bin" | grep -c "STARX" >> "$OUT"
strings -n 5 "$D/s92-staged.bin" | grep "STARX" | head -30 >> "$OUT"

e ""
e "############ 5) s90/s91/s92: cs_blob / amfi / CS_VALID 内核侧输出"
for n in 90 91; do
  e "--- s$n ---"
  strings -n 5 "$D/s${n}-log.bin" | grep -iE "cs_blob|amfi|CS_VALID|cs_invalid|CODE SIGNING|cs_validate" | head -20 >> "$OUT"
done
e "--- s92 ---"
strings -n 5 "$D/s92-staged.bin" | grep -iE "cs_blob|amfi|CS_VALID|cs_invalid|CODE SIGNING|cs_validate|CS_INITPAGE" | head -20 >> "$OUT"

e ""
e "############ 6) s90 结尾：是否进 SpringBoard 主循环（beat/UI）"
strings -n 5 "$D/s90-log.bin" | grep -E "backboardd\[39:" | tail -25 >> "$OUT"

echo OK; ls -l "$OUT"
