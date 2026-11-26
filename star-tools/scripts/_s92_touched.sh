#!/bin/bash
# 取证2：找出 s90->s91 那一轮编译期间（03:50-04:20）被改动过的所有源文件
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/touched.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "===== 1) 源码树中 mtime 在 11-17 03:40 .. 04:30 之间的文件 ====="
find "$SRC" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' -o -name '*.cpp' -o -name '*.s' \) \
  -newermt '2026-11-17 03:40:00' ! -newermt '2026-11-17 04:30:00' \
  -not -path '*/BUILD/*' -printf '%TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null | sort >> "$OUT"

e ""
e "===== 2) 全树（含 BUILD）同窗口改动，按时间排序，前 60 ====="
find "$SRC" -type f -newermt '2026-11-17 03:40:00' ! -newermt '2026-11-17 04:30:00' \
  -printf '%TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null | sort | head -60 >> "$OUT"

e ""
e "===== 3) BUILD 产物 mtime（判断内核重建时刻） ====="
ls -l --time-style=+%Y-%m-%d\ %H:%M:%S "$SRC/BUILD/obj/RELEASE_ARM64_BCM2837/" 2>/dev/null | grep -E "mach|kernel" >> "$OUT"

e ""
e "===== 4) /root/star26 下 s85..s92 各轮目录 ====="
ls -ld --time-style=+%Y-%m-%d\ %H:%M:%S /root/star26/s8*/ /root/star26/s9*/ 2>/dev/null >> "$OUT"

e ""
e "===== 5) 各轮内核 md5（若保留） ====="
for n in 85 86 87 88 89 90 91 92; do
  for p in /root/star26/s$n/parts/kernelcache /root/star26/s$n/kernel /root/star26/s$n/mach.release*; do
    [ -f "$p" ] && e "s$n: $p  $(md5sum "$p" | cut -d' ' -f1)  $(stat -c%s "$p")"
  done
done

e ""
e "===== 6) cmdline：从 s90/s91/s92 boot.img 明文区抓 ====="
for n in 90 91 92; do
  e "--- s$n ---"
  strings -n 4 /mnt/c/ios26/s$n-boot.img | grep -E "cpus=|applog=|metal=|fb_flip|fb_dcs|fb_dim|star_cs|loader_return|pac_emu|amfi|debug=" >> "$OUT"
done

echo OK; ls -l "$OUT"
