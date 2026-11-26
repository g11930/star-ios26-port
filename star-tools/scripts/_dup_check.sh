#!/bin/bash
R=/root/star26/star-native
echo "===== annibale_gpu_temperature 全树定义（应只有头文件声明 + 我新加的 1 个实现）====="
grep -rn "annibale_gpu_temperature" "$R" --include=*.c --include=*.h --include=*.cpp 2>/dev/null
echo
echo "===== annibale_gpu_speed 全树定义（C++ weak 桩 + 我的强符号）====="
grep -rn "annibale_gpu_speed" "$R" --include=*.c --include=*.h --include=*.cpp 2>/dev/null
echo
echo "===== star_platform_stubs.c 里的相关空桩 ====="
grep -n "annibale_gpu\|annibale_cpufreq_touched" "$R"/bsd/dev/star/star_platform_stubs.c 2>/dev/null
