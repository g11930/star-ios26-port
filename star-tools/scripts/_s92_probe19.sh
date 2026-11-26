#!/bin/bash
# probe19: cs_debug 后门路径 + 运行时是否打 CODE SIGNING + CS_DEBUGGED 可行性
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/probe19.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "/mnt/c/ios26/s92-staged.bin"; else echo "/mnt/c/ios26/s$1-log.bin"; fi; }

e "############ 1) kern_cs.c:190-250 （cs_debug 路径 / CS_DEBUGGED 设置） ===================================="
sed -n '190,250p' "$SRC/bsd/kern/kern_cs.c" >> "$OUT"

e ""
e "############ 2) kern_cs.c:170-190 （boot-arg 解析） ===================================="
sed -n '170,192p' "$SRC/bsd/kern/kern_cs.c" >> "$OUT"

e ""
e "############ 3) 运行时日志里是否有 'CODE SIGNING:' / 'Invalidated flags' ===================================="
for n in 89 90 91 s92; do
  f=$(L $n)
  e "  $n : CODE_SIGNING=$(strings -n 5 "$f" | grep -c 'CODE SIGNING:')  InvalidatedFlags=$(strings -n 5 "$f" | grep -c 'Invalidated flags')  cs_invalid=$(strings -n 5 "$f" | grep -c 'cs_invalid_page')"
done
e "--- s91/s92 若有，打印出来 ---"
for n in 91 s92; do
  f=$(L $n)
  strings -n 5 "$f" | grep -E 'CODE SIGNING:|Invalidated flags|cs_invalid_page|cs_process_invalidated' | head -10 >> "$OUT"
done

e ""
e "############ 4) csops 相关：谁调用了 csproc_get_validation_category / csops ===================================="
grep -rn "csproc_get_validation_category\|validation_category" "$SRC/bsd/kern/kern_cs.c" | head -20 >> "$OUT"

e ""
e "############ 5) amfi 里 entitlements 校验入口（error=22 上游） ===================================="
grep -rn "OSEntitlements\|amfi->\|amfi_" "$SRC/bsd/kern/kern_cs.c" | head -25 >> "$OUT"

e ""
e "############ 6) 是否 star 有 A12+ 专属的 CS 绕过（cs_require_lv / amfi 桩） ===================================="
find "$SRC" -name '*amfi*' -o -name '*AMFI*' 2>/dev/null | grep -v BUILD | head -20 >> "$OUT"
e "--- amfi stub/export 目录 ---"
ls -la "$SRC/../" 2>/dev/null | head -40 >> "$OUT"

e ""
e "############ 7) hackios-xnu-userland 里 amfi/codesign 补丁 ===================================="
find /root/star26/hackios-xnu-userland -iname '*amfi*' -o -iname '*codesign*' -o -iname '*cs_' 2>/dev/null | head -20 >> "$OUT"

e ""
e "############ 8) s91 vs s92 cmdline 差异复核（确认唯一变量） ===================================="
e "--- s91 ---"; cat /root/star26/s91/parts/cmdline >> "$OUT"; e ""
e "--- s92 ---"; cat /root/star26/s92/parts/cmdline >> "$OUT"; e ""

e ""
e "############ 9) s92 的 star_cs_keep_valid 为何无效（代码复核） ===================================="
sed -n '1820,1875p' "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

echo OK; ls -l "$OUT"
