#!/bin/bash
echo "=== [1] any a6xx_hfi / adreno hfi reference locally ==="
find /root/star26 -name "a6xx_hfi*" -o -name "adreno_gpu*" -o -name "a6xx_gmu*" 2>/dev/null | head -20
echo
echo "=== [2] grep ddr_wait / build_bw_table anywhere (mesa/kernel refs) ==="
grep -rln "ddr_wait\|build_bw_table" /root/star26 --include="*.c" --include="*.h" 2>/dev/null | head -20
echo
echo "=== [3] star dt: gpu pwrlevels source (what the loader reads) ==="
grep -rn "gpu-pwrlevels\|gpu_pwrlevel\|gpu-freq" /root/star26/star-native --include="*.c" --include="*.h" 2>/dev/null | head -20
echo
echo "=== [4] what our driver says about dt levels (comment near speeds) ==="
grep -n -B6 -A6 "315000, 64" /root/star26/star-native/bsd/dev/star/annibale_adreno.c
