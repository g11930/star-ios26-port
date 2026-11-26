#!/bin/bash
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/annibale_goodix.o
ls -l $O
echo "--- strings in object ---"
strings -n 6 $O | grep -i 'goodix\|touch screen' | head -10
echo "--- size of text ---"
size $O 2>/dev/null || true
echo "--- head of source ---"
sed -n '1,20p' /root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "--- any #if guard ---"
grep -n '#if' /root/star26/star-native/bsd/dev/star/annibale_goodix.c | head -6
</>
