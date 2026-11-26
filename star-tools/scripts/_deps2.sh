#!/bin/bash
S=/root/star26/star-native/bsd/dev/star
echo "===== star 侧: boost/touch/focal/context_drained 是否存在 ====="
grep -rn "annibale_cpufreq_touched\|annibale_perfctl_gpu_interactive_active\|annibale_gpu_focal_active\|annibale_context_drained\|annibale_gpu_temperature" "$S" 2>/dev/null | head -20
echo
echo "===== K90 侧这些函数定义 ====="
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev
grep -rn "annibale_cpufreq_touched\|annibale_perfctl_gpu_interactive_active\|annibale_gpu_focal_active\|annibale_context_drained\|annibale_gpu_temperature" "$K" 2>/dev/null | grep -v "\.o:" | head -20
