#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. cs_invalid_page 调用者 ==="
grep -rn 'cs_invalid_page' $T --include=*.c --include=*.h 2>/dev/null | grep -v BUILD | head -20
echo
echo "=== B. mark_invalid_allowed ==="
grep -rn 'mark_invalid_allowed' $T --include=*.c 2>/dev/null | grep -v BUILD | head -20
echo
echo "=== C. cs_validate_page / page validation 调用者 ==="
grep -rn 'cs_validate_page\|cs_validate_range' $T --include=*.c 2>/dev/null | grep -v BUILD | head -30
echo
echo "=== D. userland accelerator 源 ==="
ls /root/star26/hackios-xnu-userland/userland/src/ 2>/dev/null | head -40
echo "--- find accelerator sources ---"
find /root/star26/hackios-xnu-userland -type f \( -name '*.m' -o -name '*.mm' -o -name '*.swift' -o -name '*.c' -o -name '*.cpp' -o -name '*.h' \) 2>/dev/null | xargs grep -ln 'Accelerator\|sgx\|IOAccelerator' 2>/dev/null | head -20
echo
echo "=== E. userland 24h 内修改的源文件 ==="
find /root/star26/hackios-xnu-userland -newermt '2026-11-15 00:00' -type f 2>/dev/null | grep -v '\.o$\|\.d$\|built\|\.a$' | head -40
echo "=== DONE ==="
