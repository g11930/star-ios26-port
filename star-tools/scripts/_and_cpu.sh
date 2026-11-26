#!/bin/bash
# 抓 Android 侧 CPU / SoC 信息，与 iOS 侧比对
A=/d/桌面/adb-fastboot/adb.exe
export MSYS_NO_PATHCONV=1

echo "===== ro.* 关键属性 ====="
"$A" shell getprop ro.hardware 2>&1 | tr -d '\r'
"$A" shell getprop ro.board.platform 2>&1 | tr -d '\r'
"$A" shell getprop ro.soc.model 2>&1 | tr -d '\r'
"$A" shell getprop ro.product.device 2>&1 | tr -d '\r'
"$A" shell getprop ro.boot.hardware 2>&1 | tr -d '\r'
"$A" shell getprop ro.board.soc_model 2>&1 | tr -d '\r'
"$A" shell getprop ro.hardware.egl 2>&1 | tr -d '\r'

echo "===== /proc/cpuinfo (前 25 行) ====="
"$A" shell "cat /proc/cpuinfo" 2>&1 | tr -d '\r' | head -25

echo "===== CPU 频率 (scaling_cur_freq / cpuinfo_cur_freq) ====="
"$A" shell "for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do echo -n \"$c: \"; cat \$c 2>/dev/null; done" 2>&1 | tr -d '\r' | head -12

echo "===== 可用频率档位 (lscpu) ====="
"$A" shell "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies 2>/dev/null; cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_available_frequencies 2>/dev/null" 2>&1 | tr -d '\r'
