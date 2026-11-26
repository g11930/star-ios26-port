#!/bin/bash
cd /root/star26/star-native || exit 1
echo "===== 1) kern_minimac.c 40-105 ====="
sed -n '40,105p' bsd/kern/kern_minimac.c
echo
echo "===== 2) miniamfi_ops table 210-250 ====="
sed -n '210,250p' bsd/kern/kern_minimac.c
echo
echo "===== 3) CS_SIGNED set sites (non-.bak) ====="
grep -rn "CS_SIGNED" --include=*.c --include=*.h . 2>/dev/null | grep -v "\.bak" | head -30
echo
echo "===== 4) MACF call site for vnode_check_signature ====="
grep -rn "mac_vnode_check_signature" --include=*.c --include=*.h --include=*.inc . 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "===== 5) our IOLog markers inside live log (s96) ====="
for pat in "star_kv" "star_cs" "miniamfi" "STARCS" "MMCS"; do
  echo "--- pattern: $pat"
  strings -n 5 /mnt/c/ios26/s96-live.bin | grep -c "$pat"
done
echo
echo "===== 6) sample kernel-side IOLog lines in s96 live ====="
strings -n 10 /mnt/c/ios26/s96-live.bin | grep -E "^star|STAR|star_" | head -20
echo
echo "===== 7) does the kernel binary have the ops field wired? (nm/objdump look for reloc) ====="
nm -m BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 2>/dev/null | grep -i "miniamfi" | head -20
echo
echo "===== DONE ====="
