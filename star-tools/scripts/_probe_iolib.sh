#!/bin/bash
echo "== IOLog use in bsd/dev/star =="
grep -rn "IOLog" /root/star26/star-native/bsd/dev/star/*.c 2>/dev/null | head -6
echo "== includes of annibale_ufshc.c =="
sed -n '1,30p' /root/star26/star-native/bsd/dev/star/annibale_ufshc.c
echo "== does star_platform_stubs.c include IOLib =="
grep -n "include" /root/star26/star-native/bsd/dev/star/star_platform_stubs.c | head -20
echo "== tail of star_platform_stubs.c =="
tail -25 /root/star26/star-native/bsd/dev/star/star_platform_stubs.c
