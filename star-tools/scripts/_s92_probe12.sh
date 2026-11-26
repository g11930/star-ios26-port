#!/bin/bash
# probe12: STARX tag 分布 + CS_INITPAGE 是否真跑 + s90/s91 backboardd 启动序列 diff
D=/mnt/c/ios26
SRC=/root/star26/star-native
OUT=$D/probe12.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "$D/s92-staged.bin"; else echo "$D/s$1-log.bin"; fi; }

e "############ 1) 各轮 STARX tag 直方图（只统计 tag，不统计 payload）"
for n in 89 90 91 s92; do
  f=$(L $n)
  e "--- $n ---"
  strings -n 5 "$f" | grep -o 'STARX [A-Z0-9_]*' | sort | uniq -c | sort -rn >> "$OUT"
done

e ""
e "############ 2) CS_* 探针 tag 出现情况（s92 核心验证）"
for n in 90 91 s92; do
  f=$(L $n)
  e "--- $n ---"
  for t in CS_INITPAGE_BAD CS_INITPAGE_F CS_INITPAGE_CTX CS_LIP; do
    e "  $(printf '%-20s' "$t") $(strings -n 5 "$f" | grep -c -- "$t")"
  done
done
e "--- s92 里所有含 CS_ 的 STARX 行 ---"
strings -n 5 "$D/s92-staged.bin" | grep -E 'STARX CS_' | head -30 >> "$OUT"
e "(以上为空则 star_cs_probe 未生效)"

e ""
e "############ 3) s92 里 mach_loader 的初始页校验是否被触发（看 error=22 与 exec 失败）"
e "s92 error=22 计数: $(strings -n 5 $D/s92-staged.bin | grep -c 'error=22')"
e "s92 SecTaskLoadEntitlements: $(strings -n 5 $D/s92-staged.bin | grep -c 'SecTaskLoadEntitlements failed')"
strings -n 5 "$D/s92-staged.bin" | grep -E 'SecTaskLoadEntitlements failed' | sort | uniq -c | sort -rn | head -12 >> "$OUT"

e ""
e "############ 4) s90 vs s91 backboardd 首次启动序列（前 70 行含 Main/Metal/GPU）"
for n in 90 91; do
  f=$(L $n)
  e "=== s$n backboardd 最早 70 行 ==="
  strings -n 5 "$f" | grep -E "backboardd\[[0-9]+:" | head -70 >> "$OUT"
done

e ""
e "############ 5) s90/s91 SpringBoard 时间线（首末 PID/时间）"
for n in 90 91; do
  f=$(L $n)
  e "--- s$n ---"
  e "SpringBoard 行数=$(strings -n 5 "$f" | grep -c 'SpringBoard\[')"
  strings -n 5 "$f" | grep -E 'SpringBoard\[[0-9]+:' | head -2 >> "$OUT"
  e "  ..."
  strings -n 5 "$f" | grep -E 'SpringBoard\[[0-9]+:' | tail -2 >> "$OUT"
  e "P28EXIT SpringBoard 次数=$(strings -n 5 "$f" | grep -c 'P28EXIT: pid [0-9]* SpringBoard')"
  e "P28EXIT backboardd 次数=$(strings -n 5 "$f" | grep -c 'P28EXIT: pid [0-9]* backboardd')"
done

e ""
e "############ 6) s90 里 backboardd[39] 的 Metal/GPU 相关行（全量，看它走了哪条路）"
strings -n 5 "$D/s90-log.bin" | grep -E "(annibalemetal|IOAccelerator|sgx|GPU|MTL)" | head -40 >> "$OUT"

echo OK; ls -l "$OUT"
