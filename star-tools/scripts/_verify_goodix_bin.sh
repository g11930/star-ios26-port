#!/bin/bash
M=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
K=/root/star26/s111/parts/kernel
echo "--- mach exists ---"; ls -l $M 2>&1 | tail -1
echo "mach goodix-strings: $(strings -n 8 $M | grep -c 'goodix')"
strings -n 8 $M | grep 'goodix' | head -8
echo "--- packaged kernel strings ---"
strings -n 8 $K | grep 'goodix' | head -8
echo "--- symbols ---"
grep -c annibale_goodix_init /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/System.map 2>/dev/null
find /root/star26/star-native/BUILD -name 'System.map*' | head -3
</>
