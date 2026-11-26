#!/bin/bash
echo "########## 1. 内核侧探针源码 + 备份（当前树） ##########"
ls -la /root/star26/star-native/osfmk/kern/star_msgprobe_k.c* 2>/dev/null | awk '{print $5, $9}'
ls -la /root/star26/star-native/bsd/dev/star/star_msgprobe.c* 2>/dev/null | awk '{print $5, $9}'
echo
echo "########## 2. 其他 star_* 内核源文件 ##########"
find /root/star26/star-native -name "star_*.c" -o -name "star_*.h" 2>/dev/null | grep -vE "BUILD/" | sort | head -40
echo
echo "########## 3. apply 类脚本（改内核的，关键） ##########"
ls /mnt/d/桌面/star26-deps/scripts/apply-*.py 2>/dev/null | xargs -n1 basename
echo
echo "########## 4. make/run/fetch/build 核心脚本 ##########"
ls /mnt/d/桌面/star26-deps/scripts/ | grep -E "^(make-|mk-|run-full|fetch-|build-star|repack-|reseal-|fb2png|mks[0-9]|starcat)" | sort | head -60
echo
echo "########## 5. 关键产物（镜像/日志/帧缓冲） ##########"
ls -la /mnt/c/ios26/*.img 2>/dev/null | tail -12 | awk '{print $5, $9}'
echo "--- 最新日志 ---"
ls -la /mnt/c/ios26/s7*-log*.bin /mnt/c/ios26/s7*-frame*.raw 2>/dev/null | awk '{print $5, $9}' | tail -12
