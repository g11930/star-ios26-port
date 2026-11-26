#!/bin/bash
cd /root/star26/star-native || exit 1
echo "===== 1) git status (short) ====="
git status --short | head -60
echo
echo "===== 2) CS_VALID / star_cs hits in tree (excl .bak) ====="
grep -rn "CS_VALID\|star_cs_valid\|star_cs_keep_valid\|STAR_CS" --include=*.c --include=*.h --include=*.inc --include=*.cpp . 2>/dev/null | grep -v "\.bak" | head -40
echo
echo "===== 3) miniamfi_ops table ====="
grep -n "miniamfi_ops\s*=\|mpc_vnode_check_signature\|mpc_ops" bsd/kern/kern_minimac.c | head -20
echo
sed -n '/struct mac_policy_ops) miniamfi_ops/,/^};/p' bsd/kern/kern_minimac.c | head -60
echo
echo "===== 4) CS_VALID value in headers ====="
grep -rn "define CS_VALID\|define CS_SIGNED\|define CS_ADHOC\|define CS_PLATFORM_BINARY\|define CS_SIGNED" bsd/sys/*.h osfmk 2>/dev/null | head -20
echo
echo "===== 5) where CS_VALID is set in kernel (non-.bak) ====="
grep -rn "CS_VALID" --include=*.c . 2>/dev/null | grep -v "\.bak" | head -40
echo
echo "===== 6) s96 live log markers ====="
for f in /mnt/c/ios26/s96-live.bin /mnt/c/ios26/s95-live.bin; do
  [ -f "$f" ] || continue
  echo "--- $f ($(stat -c%s "$f") B)"
  strings -n 6 "$f" | grep -E "star_cs|MMCS|minimac|miniamfi|SecTaskLoadEntitlements failed|NOT_CODESIGNED" | head -25
done
echo
echo "===== DONE ====="
