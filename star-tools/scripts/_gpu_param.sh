#!/bin/bash
cd /root/star26/star-native
echo "=== GET_PARAM ids handled ==="
grep -rn 'kMsmGetParam\|GET_PARAM' --include=*.cpp --include=*.c --include=*.h . | grep -v BUILD | head -10
echo "=== 0x14 / MAX_FREQ ==="
grep -rn 'MAX_FREQ\|MAXFREQ\|0x14' iokit/Kernel/AnnibaleGPU.cpp 2>/dev/null | head -10
echo "=== gpu freq / clock vote in adreno driver ==="
grep -rn -i 'freq\|clk\|vote' bsd/dev/star/annibale_adreno.c | head -20
</