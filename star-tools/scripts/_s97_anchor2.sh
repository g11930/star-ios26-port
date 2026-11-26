#!/bash
cd /root/star26/star-native || exit 1
echo "===== A) STARTUP_RANK constants ====="
grep -n "STARTUP_RANK" osfmk/libkern/section_keywords.h libkern/libkern/section_keywords.h 2>/dev/null | head -20
find . -name section_keywords.h | head -3
echo
echo "===== B) kern_exec.c 8980-9015 ====="
sed -n '8980,9015p' bsd/kern/kern_exec.c
echo
echo "===== DONE ====="
