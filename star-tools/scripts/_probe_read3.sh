#!/bin/bash
echo "########## struct turnstile 336-375 ##########"
sed -n '336,375p' /root/star26/star-native/osfmk/kern/turnstile.h
echo
echo "########## turnstile_type_t 枚举 ##########"
grep -n "turnstile_type_t\|TURNSTILE_SYNC_IPC\|TURNSTILE_PROPRIETOR\|ts_proprietor\|ts_type" /root/star26/star-native/osfmk/kern/turnstile.h | head -40
echo
echo "########## ipc_mqueue 的 turnstile 字段（SEND 阻塞的 port 从这里反查） ##########"
grep -n "turnstile\|imq_turnstile\|TURNSTILE_SYNC_IPC" /root/star26/star-native/osfmk/ipc/ipc_mqueue.h 2>/dev/null | head -30
echo
echo "########## ipc_port 的 turnstile / mqueue 字段 ##########"
grep -n "turnstile\|ip_turnstile\|imq\|ip_mqueue" /root/star26/star-native/osfmk/ipc/ipc_port.h | head -30
echo
echo "########## proprietor 到 port 的转换（SYNC_IPC turnstile 的 proprietor 是 port 的地址?） ##########"
grep -n "proprietor\|TURNSTILE_SYNC_IPC\|ipc_port" /root/star26/star-native/osfmk/kern/turnstile.c | grep -iE "port|proprietor" | head -40
