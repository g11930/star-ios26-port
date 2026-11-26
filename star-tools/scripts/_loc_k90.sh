#!/bin/bash
echo "===== StarDisplayCompat.cpp 95..130 (weak stubs) ====="
sed -n '95,130p' /root/star26/star-native/iokit/Kernel/StarDisplayCompat.cpp
echo
echo "===== find K90 adreno8_hfi.c ====="
find /root/star26/k90ref -iname "adreno8_hfi.c" 2>/dev/null | head
find /root -maxdepth 4 -iname "adreno8_hfi.c" 2>/dev/null | head
echo
echo "===== annibale_gpu_temperature decl anywhere ====="
grep -rn "annibale_gpu_temperature" /root/star26/star-native/ 2>/dev/null | head
