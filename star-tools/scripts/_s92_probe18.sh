#!/bin/bash
# probe18: 收口 —— cs_invalid_page 符号/调用、annibale dylib 签名状态、CS_HARD/CS_DEBUGGED 可用性
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/probe18.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L(){ if [ "$1" = "s92" ]; then echo "/mnt/c/ios26/s92-staged.bin"; else echo "/mnt/c/ios26/s$1-log.bin"; fi; }

e "############ 1) 内核镜像里 cs_invalid_page / cs_process_invalidated 符号 ===================================="
for k in s91 s92; do
  kf=/root/star26/$k/parts/kernel
  e "--- $k kernel: $(stat -c%s $kf 2>/dev/null) B ---"
  for sym in cs_invalid_page cs_process_invalidated csblob_invalidate_flags csvnode_invalidate_flags cs_procs_invalidated "Invalidated flags" "CODE SIGNING:" "cs_invalid"; do
    e "  $(printf '%-30s' "$sym") $(strings -n 6 "$kf" 2>/dev/null | grep -c -- "$sym")"
  done
done

e ""
e "############ 2) 是否有 CS_HARD/CS_DEBUGGED 的 boot-arg 后门（可绕过 CS_VALID） ===================================="
grep -rn "CS_HARD\|CS_DEBUGGED\|cs_force_hard\|cs_force_kill\|cs_debug" "$SRC/bsd/kern/kern_cs.c" | head -30 >> "$OUT"
e "--- cs_force_hard 定义/赋值 ---"
grep -rn "cs_force_hard\|cs_force_kill" "$SRC" --include=*.c --include=*.h 2>/dev/null | head -20 >> "$OUT"

e ""
e "############ 3) amfi 侧 CS_VALID 相关（谁在 amfi hook 里清） ===================================="
grep -rn "CS_VALID\|csb_flags" "$SRC/bsd/kern/ubc_subr.c" | sed -n '1,30p' >> "$OUT"

e ""
e "############ 4) 页校验入口：vm_fault / cs_invalid_page 调用点 ===================================="
grep -rn "cs_invalid_page" "$SRC" --include=*.c --include=*.h 2>/dev/null >> "$OUT"

e ""
e "############ 5) Circle: s91 里 annibalemetal 加载与 error=22 的时间先后（行号差） ===================================="
f=$(L 91)
e "-- 各关键行在 strings 输出里的行号 --"
for pat in 'registration completed device=1' 'adopted native default device' 'error=22' 'no AnnibaleGPU service' 'Terminating app due to uncaught exception'; do
  n=$(strings -n 5 "$f" | grep -n -- "$pat" | head -1 | cut -d: -f1)
  e "  $(printf '%-45s' "$pat") -> line $n"
done

e ""
e "############ 6) s90: 同样查这两行的行号（对照） ===================================="
f=$(L 90)
for pat in 'registration completed device=1' 'adopted native default device' 'error=22' 'no AnnibaleGPU service'; do
  n=$(strings -n 5 "$f" | grep -n -- "$pat" | head -1 | cut -d: -f1)
  e "  $(printf '%-45s' "$pat") -> line $n"
done

e ""
e "############ 7) s89/s90/s91: libannibalemetal 的加载痕迹（dlopen/load） ===================================="
for n in 90 91; do
  f=$(L $n)
  e "=== $n ==="
  strings -n 5 "$f" | grep -iE 'libannibalemetal|AnnibaleMetal\.bundle|annibale.*load|dlopen' | head -15 >> "$OUT"
done

e ""
e "############ 8) sbmetal26 注入器源码位置 ===================================="
find /root/star26/hackios-xnu-userland -name '*sb_metal*' -o -name '*sbmetal*' 2>/dev/null | head -20 >> "$OUT"

e ""
e "############ 9) kalloc 闸门当前状态 ===================================="
ls -la /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>/dev/null >> "$OUT"
grep -n "def main\|argparse\|--check\|--apply\|PASS\|FAIL" /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>/dev/null | head -20 >> "$OUT"

echo OK; ls -l "$OUT"
