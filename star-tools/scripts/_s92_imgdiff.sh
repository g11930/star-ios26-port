#!/bin/bash
# 取证：s90 / s91 / s92 boot.img 的 cmdline + 内核差异
D=/mnt/c/ios26
OUT=$D/imgdiff.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

for n in 90 91 92; do
  f="$D/s${n}-boot.img"
  e ""
  e "############ s${n}-boot.img  size=$(stat -c%s $f)  md5=$(md5sum $f | cut -d' ' -f1)"
  e "--- cmdline (strings 抓 boot-arg 形态) ---"
  strings -n 8 "$f" | grep -E "^(cpus|applog|metal|fb_|star_|loader_return|nvram|debug|kext|systrace|cpufreq|pac_emu|amfi|cs_)" | head -30 >> "$OUT"
  e "--- 关键词命中 ---"
  for k in 'star_cs_probe' 'star_cs_keep_valid' 'AnnibaleMetal' 'MetalPluginName' 'MetalPluginClassName' 'sgx'; do
    c=$(strings -n 6 "$f" | grep -c -- "$k")
    e "  $(printf '%-24s' "$k") $c"
  done
done

e ""
e "############ 内核段比较（从 img 里切出 kernel 区并取 md5）"
for n in 90 91 92; do
  f="$D/s${n}-boot.img"
  # 内核通常是 img 里连续大块；用 strings 抽 IOAcceleratorES 上下文行号判断
  e "--- s${n}: IOAcceleratorES 相关字符串全量 ---"
  strings -n 6 "$f" | grep -n -E "IOAcceleratorES|AnnibaleMetal|sbmetal26" >> "$OUT"
done

echo OK; ls -l "$OUT"
