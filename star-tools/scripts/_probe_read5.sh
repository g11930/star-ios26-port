#!/bin/bash
echo "########## union turnstile_type_gencount 定义 ##########"
grep -n "union turnstile_type_gencount" /root/star26/star-native/osfmk/kern/turnstile.h /root/star26/star-native/osfmk/kern/turnstile.c
echo "--- turnstile.c 195-212 ---"
sed -n '195,212p' /root/star26/star-native/osfmk/kern/turnstile.c
echo "--- 定义处上下文 ---"
L=$(grep -n "union turnstile_type_gencount" /root/star26/star-native/osfmk/kern/turnstile.c | head -1 | cut -d: -f1); echo "line=$L"; sed -n "$((L-3)),$((L+15))p" /root/star26/star-native/osfmk/kern/turnstile.c
echo
echo "########## turnstile_type_mask / TS_TYPE_BITS ##########"
grep -rn "TS_TYPE\|type_gencount\|TURNSTILE_TYPE" /root/star26/star-native/osfmk/kern/turnstile.c | head -20
echo
echo "########## port_send_turnstile 与 ip_send_turnstile 偏移可访问性 ##########"
grep -n "ip_send_turnstile\|port_send_turnstile" /root/star26/star-native/osfmk/ipc/ipc_port.h | head -10
