#!/bin/bash
# 取证4：s92 轮目录内容 / cmdline / s92 相对 s91 的源码改动
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/probe4.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "===== 1) /root/star26/s90 s91 s92 目录树 ====="
for n in 90 91 92; do
  e "--- s$n ---"
  ls -la --time-style=+%m-%d\ %H:%M /root/star26/s$n/ >> "$OUT" 2>&1
  [ -d /root/star26/s$n/parts ] && ls -la --time-style=+%m-%d\ %H:%M /root/star26/s$n/parts/ >> "$OUT" 2>&1
done

e ""
e "===== 2) 全树找 cmdline / bootargs 记录文件 ====="
find /root/star26 -maxdepth 3 -type f \( -name '*cmdline*' -o -name '*bootarg*' -o -name '*.args' -o -name '*boot.cfg' \) -printf '%m-%d %TH:%TM  %p\n' 2>/dev/null | sort >> "$OUT"

e ""
e "===== 3) make-boot.py 里 cmdline 的默认值与来源 ====="
grep -n -E "cmdline|bootargs|star_cs|metal=|cpus=" /mnt/d/桌面/star26-deps/scripts/make-boot.py 2>/dev/null | head -40 >> "$OUT"

e ""
e "===== 4) s92 相对 s91 的源码改动（时间戳法）====="
find "$SRC" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' -o -name '*.cpp' -o -name '*.s' \) \
  -newermt '2026-11-17 04:14:30' -not -path '*/BUILD/*' \
  -printf '%TH:%TM:%TS  %p\n' 2>/dev/null | sort >> "$OUT"

e ""
e "===== 5) mach_loader.c 里探针完整实现（含 boot-arg 名）====="
sed -n '720,760p' "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

e ""
e "===== 6) 是否有 s90/s91 内核产物留存可对比 ====="
ls -l --time-style=+%m-%d\ %H:%M /root/star26/s9*/parts/ 2>/dev/null | head -40 >> "$OUT"

echo OK; ls -l "$OUT"
