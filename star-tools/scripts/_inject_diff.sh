#!/bin/bash
# 对比 star 与 K90 参考的 inject_sb26.c 初始化/安装流程差异
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
OUT=/mnt/c/ios26/inject_sb26_diff.out
: > "$OUT"

echo "=== function/inject list: star ===" >> "$OUT"
grep -nE '^(static )?(void|int|BOOL|id|Class|IMP|double|float|uint|unsigned|bool) [a-zA-Z_]+\(' "$S" | sed 's/(.*//' >> "$OUT"
echo "" >> "$OUT"
echo "=== function/inject list: K90-ref ===" >> "$OUT"
grep -nE '^(static )?(void|int|BOOL|id|Class|IMP|double|float|uint|unsigned|bool) [a-zA-Z_]+\(' "$K" | sed 's/(.*//' >> "$OUT"

echo "" >> "$OUT"
echo "=== method hook targets: star (checked_method / makeSymbolHook) ===" >> "$OUT"
grep -oE 'checked_method\("[^"]+"|"[A-Za-z0-9_]+", *"[^"]+"' "$S" | sort -u >> "$OUT"
echo "" >> "$OUT"
echo "=== method hook targets: K90-ref ===" >> "$OUT"
grep -oE 'checked_method\("[^"]+"|"[A-Za-z0-9_]+", *"[^"]+"' "$K" | sort -u >> "$OUT"

echo "" >> "$OUT"
echo "=== install / entry call sites: star ===" >> "$OUT"
grep -nE 'install_[a-z_]+\(|sb26_install|CheckedMethod|DYLD_INSERT' "$S" | tail -40 >> "$OUT"
echo "" >> "$OUT"
echo "=== install / entry call sites: K90-ref ===" >> "$OUT"
grep -nE 'install_[a-z_]+\(|sb26_install|CheckedMethod|DYLD_INSERT' "$K" | tail -40 >> "$OUT"

echo "" >> "$OUT"
echo "=== init/entry tail: star (last 60 lines) ===" >> "$OUT"
tail -60 "$S" >> "$OUT"
echo "" >> "$OUT"
echo "=== init/entry tail: K90-ref (last 60 lines) ===" >> "$OUT"
tail -60 "$K" >> "$OUT"

echo "OK $(wc -c < "$OUT") bytes"
