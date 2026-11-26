#!/bin/bash
echo "===== star 侧 boost 相关函数实现情况 ====="
for sym in annibale_cpufreq_touched annibale_cpufreq_touch annibale_perfctl_gpu_interactive_active annibale_gpu_focal_active annibale_touch_last; do
  printf "%-40s " "$sym"
  r=$(grep -rn "$sym" /root/star26/star-native/bsd/dev/ /root/star26/star-native/bsd/sys/ 2>/dev/null | grep -v "\.h:" | grep -v "extern" | head -2)
  if [ -z "$r" ]; then echo "(仅声明，无实现)"; else echo "$r"; fi
done
echo
echo "===== hfi_send 签名 ====="
sed -n '2230,2245p' /root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo
echo "===== gpu_kept 定义 ====="
grep -n "gpu_kept" /root/star26/star-native/bsd/dev/star/annibale_adreno.c | head -5
echo
echo "===== need() / rd() 宏 ====="
grep -n "^need\|#define need\|static.*need(" /root/star26/star-native/bsd/dev/star/annibale_adreno.c | head -5
