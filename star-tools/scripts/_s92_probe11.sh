#!/bin/bash
# 终局取证：PearlEventFilter/BiometricKit / Metal 加载痕迹 / star_trace 实现 / 崩溃窗口
D=/mnt/c/ios26
SRC=/root/star26/star-native
OUT=$D/probe11.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) PearlEventFilter / BiometricKit / NSURL 各轮命中"
for n in 89 90 91; do
  e "--- s$n ---"
  e "PearlEventFilter=$(strings -n 5 $D/s${n}-log.bin | grep -c PearlEventFilter)  BiometricKit=$(strings -n 5 $D/s${n}-log.bin | grep -c BiometricKit)  NSURL_nil=$(strings -n 5 $D/s${n}-log.bin | grep -c 'NSURL initFileURLWithPath')"
  strings -n 5 "$D/s${n}-log.bin" | grep -E "NSURL initFileURLWithPath" | head -5 >> "$OUT"
done
e "--- s92 ---"
e "PearlEventFilter=$(strings -n 5 $D/s92-staged.bin | grep -c PearlEventFilter)  BiometricKit=$(strings -n 5 $D/s92-staged.bin | grep -c BiometricKit)  NSURL_nil=$(strings -n 5 $D/s92-staged.bin | grep -c 'NSURL initFileURLWithPath')"
strings -n 5 "$D/s92-staged.bin" | grep -E "NSURL initFileURLWithPath" | head -5 >> "$OUT"

e ""
e "############ 2) s90 backboardd[39] 最后 30 行原始"
strings -n 5 "$D/s90-log.bin" | grep -E "backboardd\[39:" | tail -30 >> "$OUT"

e ""
e "############ 3) Metal / AnnibaleMetal / 插件 各轮"
for n in 89 90 91; do
  e "--- s$n counts ---"
  for k in 'AnnibaleMetal' 'MTLCreateSystemDefaultDevice' 'MetalPlugin' 'libMTLDriver' 'MTLDevice' 'metal_stubdev' 'sbmetal26'; do
    e "  $(printf '%-30s' "$k") $(strings -n 5 $D/s${n}-log.bin | grep -c -- "$k")"
  done
done
e "--- s92 ---"
for k in 'AnnibaleMetal' 'MTLCreateSystemDefaultDevice' 'MetalPlugin' 'MTLDevice' 'sbmetal26' 'P28EXIT'; do
  e "  $(printf '%-30s' "$k") $(strings -n 5 $D/s92-staged.bin | grep -c -- "$k")"
done

e ""
e "############ 4) star_trace 实现（为何 CS_INITPAGE 未输出）"
grep -rn "star_trace\b" "$SRC/bsd/dev/star/" "$SRC/bsd/kern/kern_exec.c" 2>/dev/null | head -10 >> "$OUT"
e "--- star_trace 函数体 ---"
grep -rn -A 20 "^star_trace(" "$SRC/bsd/dev/star/" 2>/dev/null | head -40 >> "$OUT"
e "--- star_trace 声明/定义位置 ---"
grep -rn "star_trace" "$SRC" --include=*.c --include=*.h --include=*.inc 2>/dev/null | grep -E "void|extern" | head -10 >> "$OUT"

e ""
e "############ 5) s91: 03:03:54.2 .. 03:05:45 窗口内 backboardd 相关 + 重拉证据"
strings -n 5 "$D/s91-log.bin" | grep -E "^2025-12-10 03:0[34]" | grep -E "backboardd|P28EXIT|launchd.*(spawn|exit|reap)|runningboardd.*(launch|start|terminat)" | head -50 >> "$OUT"

echo OK; ls -l "$OUT"
