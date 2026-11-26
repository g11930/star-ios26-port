#!/bin/bash
# probe16: CS_VALID 置位/清除路径全树排查 + load_code_signature 流程
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/probe16.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) 全树 CS_VALID 出现点 ===================================="
grep -rn "CS_VALID" "$SRC/bsd/kern/" "$SRC/bsd/dev/star/" "$SRC/osfmk/" 2>/dev/null >> "$OUT"

e ""
e "############ 2) mach_loader.c 里所有 csflags 赋值 ===================================="
grep -n "csflags" "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

e ""
e "############ 3) load_code_signature 函数体（CS_VALID 是否在此设置） ===================================="
awk '/^load_code_signature\(|static int[[:space:]]*$/{f=1} f' "$SRC/bsd/kern/mach_loader.c" 2>/dev/null | head -0
ln=$(grep -n "^load_code_signature" "$SRC/bsd/kern/mach_loader.c" | head -1 | cut -d: -f1)
e "  load_code_signature 起始行: $ln"
if [ -n "$ln" ]; then sed -n "${ln},$((ln+120))p" "$SRC/bsd/kern/mach_loader.c" >> "$OUT"; fi

e ""
e "############ 4) 初始页校验循环完整上下文（含 S92 探针，行 1800-1890） ===================================="
sed -n '1800,1890p' "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

e ""
e "############ 5) 该循环所在的函数名 ===================================="
awk 'NR<=1870 && /^[a-zA-Z_].*\(.*\)$|^static .*\(/ {last=NR": "$0} END{}' "$SRC/bsd/kern/mach_loader.c"
for L in 1870 1853 1845; do
  fn=$(awk -v L=$L 'NR<=L && /^[a-z_A-Z][a-zA-Z_0-9 \*]*\(/ {f=NR": "$0} END{print f}' "$SRC/bsd/kern/mach_loader.c")
  e "  行 $L 所属函数候选: $fn"
done

e ""
e "############ 6) cs_validate_page / amfi hook 调用点 ===================================="
grep -rn "cs_validate_page\|cs_validate_range\|CS_VALIDATE_TAINTED\|csblob_get_flags\|csflags |=" "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

e ""
e "############ 7) bsd_init.c:553 上下文（kernel task CS_VALID） ===================================="
sed -n '540,565p' "$SRC/bsd/kern/bsd_init.c" >> "$OUT"

e ""
e "############ 8) 是否有 star 专有 hack 掉 CS_VALID / codesign 的地方 ===================================="
grep -rn "CS_VALID\|csflags" "$SRC/bsd/dev/star/" 2>/dev/null | head -40 >> "$OUT"
e "  -- star 目录文件列表 --"
ls -la "$SRC/bsd/dev/star/" 2>/dev/null >> "$OUT"

e ""
e "############ 9) amfi / AppleMobileFileIntegrity 相关 star 改动 ===================================="
grep -rln "amfi\|AMFI\|AppleMobileFileIntegrity" "$SRC" --include=*.c --include=*.h --include=*.inc 2>/dev/null | head -20 >> "$OUT"

echo OK; ls -l "$OUT"
