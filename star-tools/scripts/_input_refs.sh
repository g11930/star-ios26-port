#!/bin/bash
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/annibale_input.o
echo "--- undefined refs ---"
nm -u $O 2>/dev/null | grep -i 'goodix\|adreno'
echo "--- strings input.o ---"
strings -n 6 $O | grep -i 'goodix\|device ready'
echo "--- who calls annibale_input_init ---"
grep -rn 'annibale_input_init' /root/star26/star-native/bsd/dev/star/*.c /root/star26/star-native/bsd/dev/star/*.cpp 2>/dev/null | head
</>
