#!/bin/bash
echo "########## bsd Makefile 是否给 star_msgprobe.o 加 osfmk include ##########"
grep -n "star_msgprobe" /root/star26/star-native/bsd/conf/Makefile.arm64 2>/dev/null
echo
echo "########## turnstile.h 是否能从 osfmk TU 直接 include ##########"
grep -n "kern/turnstile.h" /root/star26/star-native/osfmk/kern/kern_types.h /root/star26/star-native/osfmk/kern/thread.h 2>/dev/null | head
echo
echo "########## ZONE_ID_TURNSTILE 数值上下文 ##########"
sed -n '1625,1640p' /root/star26/star-native/osfmk/kern/zalloc.h
echo
echo "########## zone_id_for_element 声明 ##########"
grep -n "zone_id_for_element" /root/star26/star-native/osfmk/kern/zalloc.h /root/star26/star-native/osfmk/kern/zalloc_internal.h 2>/dev/null
echo
echo "########## 当前 git 状态（改前基线） ##########"
cd /root/star26/star-native && git status --short bsd/dev/star/star_msgprobe.c osfmk/kern/star_msgprobe_k.c
