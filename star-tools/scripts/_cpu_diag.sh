#!/bin/bash
echo "########## 1. s71 日志里 CPU/核心实际状态 ##########"
grep -aiE "cpufreq|cpu [0-9]|core [0-9]|processor|SCMI|cluster|frequency|MHz|GHz|cpus=|bootcpu" /mnt/c/ios26/s71-log.bin | head -40

echo
echo "########## 2. s71 cmdline 里 cpu 相关参数 ##########"
tr -d '\0' < /root/star26/s71/parts/cmdline | tr ' ' '\n' | grep -iE "cpu|core|sched|cluster"

echo
echo "########## 3. 我们树有没有 cpufreq 支持 ##########"
ls /root/star26/star-native/bsd/dev/star/*cpu* /root/star26/star-native/bsd/dev/star/*freq* 2>/dev/null
grep -rn "cpufreq\|cpu_freq\|SCMI" /root/star26/star-native/bsd/dev/star/*.c 2>/dev/null | head -15

echo
echo "########## 4. warsaw sched_prim.c.patch 内容 ##########"
head -100 "/root/ref/warsaw/xnu/patches/63-osfmk%kern%sched_prim.c.patch" 2>/dev/null
