#!/bin/bash
# 方案A改码前的只读验证：确认补丁落点、include、调用链、备份
OUT=/mnt/c/ios26/patchA_verify.out
: > "$OUT"
SRC=/root/star26/star-native/bsd/kern/kern_minimac.c
TREE=/root/star26/star-native

e() { echo "$@" >> "$OUT"; }

e "==================== 1) kern_minimac.c HEAD (includes, 1-70) ===================="
nl -ba "$SRC" | sed -n '1,70p' >> "$OUT"

e ""
e "==================== 2) miniamfi_vnode_check_signature FULL ===================="
LINE=$(grep -n 'miniamfi_vnode_check_signature' "$SRC" | head -1 | cut -d: -f1)
e "first hit line = $LINE"
START=$((LINE-15)); [ $START -lt 1 ] && START=1
END=$((LINE+70))
nl -ba "$SRC" | sed -n "${START},${END}p" >> "$OUT"

e ""
e "==================== 3) ALL hits of vnode_check_signature in kern_minimac.c ===================="
grep -n 'check_signature\|cs_flags' "$SRC" >> "$OUT"

e ""
e "==================== 4) PE_parse_boot_argn precedent in this file + static int pattern ===================="
grep -n 'PE_parse_boot_argn\|^static int\|boot_arg' "$SRC" >> "$OUT"
e "--- (for reference) mach_loader.c include of PE_parse_boot_argn header ---"
grep -n 'libkern/libkern.h\|PE_parse_boot_argn' /root/star26/star-native/bsd/kern/mach_loader.c | head -5 >> "$OUT"

e ""
e "==================== 5) who CALLS miniamfi_vnode_check_signature (MAC table) ===================="
grep -rn 'miniamfi_vnode_check_signature' "$TREE" 2>/dev/null >> "$OUT"
e "--- mac_vnode_check_signature callers in exec/ubc path ---"
grep -rn 'mac_vnode_check_signature' "$TREE/bsd/kern" "$TREE/bsd/sys" 2>/dev/null | head -20 >> "$OUT"

e ""
e "==================== 6) backup chain of kern_minimac.c ===================="
ls -la "$SRC"* >> "$OUT"

e ""
e "==================== 7) build script + stage8 gate presence ===================="
ls -la /mnt/d/桌面/star26-deps/scripts/ | grep -i 'build\|stage8\|reseal\|mkpayload' >> "$OUT"
ls -la /root/star26/star-native/*.sh 2>/dev/null >> "$OUT"

e ""
e "==================== 8) current cs-related boot args in s91 cmdline ===================="
grep -o 'star_[a-z_]*=[0-9]*\|cs_[a-z_]*=[0-9]*' /root/star26/s91/parts/cmdline >> "$OUT" 2>/dev/null || cat /root/star26/s91/parts/cmdline >> "$OUT"

e ""
e "==================== DONE ===================="
echo "OK patchA_verify.out $(wc -c < "$OUT") bytes"
