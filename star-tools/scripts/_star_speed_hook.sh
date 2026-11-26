#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star 侧 annibale_gpu_speed 空桩及调用 ====="
grep -n "annibale_gpu_speed\|gpu_speed\|speed_wanted\|the speed wanted" "$S" | head -30
echo
echo "===== star 侧 speeds[] 表与默认档 ====="
grep -n -E "speeds\[|GPU_SPEED_DEFAULT|GPU_SPEED|level|vote" "$S" | head -30
echo
echo "===== submit 路径是否在调 speed ====="
grep -n -E "submit|work|busy|idle|workload|load|throttle" "$S" | head -40
