#!/bin/bash
# probe17: cs_flags 精确解码 + CS_VALID 清除路径 + s91 内核 kalloc 闸门状态
SRC=/root/star26/star-native
OUT=/mnt/c/ios26/probe17.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }

e "############ 1) cs_blobs.h 全部 CS_ 位定义（精确解码 0x26000000） ===================================="
sed -n '25,90p' "$SRC/osfmk/kern/cs_blobs.h" >> "$OUT"
e "--- CS_ALLOWED_MACHO ---"
grep -n -A 12 "define CS_ALLOWED_MACHO" "$SRC/osfmk/kern/cs_blobs.h" >> "$OUT"

e ""
e "############ 2) kern_cs.c:260-330 （CS_VALID 清除） ===================================="
sed -n '260,330p' "$SRC/bsd/kern/kern_cs.c" >> "$OUT"

e ""
e "############ 3) kern_cs.c:490-560 （clear CS_VALID on blob / all blobs） ===================================="
sed -n '490,560p' "$SRC/bsd/kern/kern_cs.c" >> "$OUT"

e ""
e "############ 4) kern_cs.c:1030-1060 （csops 门槛 (CS_VALID|CS_DEBUGGED)==0 → EINVAL） ===================================="
sed -n '1030,1075p' "$SRC/bsd/kern/kern_cs.c" >> "$OUT"

e ""
e "############ 5) ubc_subr.c:4040-4110 （cs_blob 构建 + CS_VALID 设置） ===================================="
sed -n '4040,4110p' "$SRC/bsd/kern/ubc_subr.c" >> "$OUT"

e ""
e "############ 6) ubc_subr.c:5240-5290 （found_but_not_valid 判定） ===================================="
sed -n '5240,5290p' "$SRC/bsd/kern/ubc_subr.c" >> "$OUT"

e ""
e "############ 7) ubc_subr.c:5630-5690 （第二个 CS_VALID 设置点） ===================================="
sed -n '5630,5690p' "$SRC/bsd/kern/ubc_subr.c" >> "$OUT"

e ""
e "############ 8) mach_loader.c:3820-3880 （blob->csb_flags & CS_VALID 检查） ===================================="
sed -n '3820,3880p' "$SRC/bsd/kern/mach_loader.c" >> "$OUT"

e ""
e "############ 9) s91 内核是否跑过 stage8 kalloc 闸门 ===================================="
e "-- 查找 s91 构建日志 --"
ls -la /root/star26/s91/ 2>/dev/null >> "$OUT"
find /root/star26 -maxdepth 2 -name '*kalloc*' -o -maxdepth 2 -name '*build*.log' -o -maxdepth 2 -name '*.buildlog' 2>/dev/null | head -20 >> "$OUT"
e "-- D:/桌面/star26-deps 下的构建日志 --"
ls -la /mnt/d/桌面/star26-deps/ 2>/dev/null | head -30 >> "$OUT"
ls -la /mnt/d/桌面/star26-deps/scripts/ 2>/dev/null | grep -iE 'build|kalloc|stage' | head -20 >> "$OUT"

e ""
e "############ 10) stage8-kalloc-backfill.py --check 用法 ===================================="
ls -la /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>/dev/null >> "$OUT"
head -40 /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py 2>/dev/null >> "$OUT"

echo OK; ls -l "$OUT"
