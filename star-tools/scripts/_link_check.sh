#!/bin/bash
M=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
K=/root/star26/s111/parts/kernel
for pat in 'touch-start-delay' 'so far %u reports' 'init called' 'the touch screen is not enabled' 'thread up'; do
  echo "mach[$pat] = $(strings -n 6 $M | grep -c "$pat")   kernel = $(strings -n 6 $K | grep -c "$pat")"
done
echo "--- link list contains goodix? ---"
grep -n 'annibale_goodix' /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/Makefile | head -3
echo "--- OBJS/USER_FILES near line 60-80 ---"
sed -n '60,80p' /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/Makefile
</>
