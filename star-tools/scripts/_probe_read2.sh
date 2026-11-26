#!/bin/bash
echo "########## turnstile.h 结构定义 ##########"
grep -nE "struct turnstile|ts_object|ts_waitq|turnstile.*waitq|io_from|TS_|turnstile_lookup|turnstile_alloc" /root/star26/star-native/osfmk/kern/turnstile.h 2>/dev/null | head -60
echo
echo "########## turnstile.h 结构全文片段 ##########"
sed -n '90,180p' /root/star26/star-native/osfmk/kern/turnstile.h 2>/dev/null
echo
echo "########## turnstile 中 waitq 与 object 的关系 API ##########"
grep -nE "waitq.*turnstile|turnstile.*waitq|turnstile_to|ts_to|io_from|object.*turnstile|turnstile.*object|ts_lock|ts_object" /root/star26/star-native/osfmk/kern/turnstile.c 2>/dev/null | head -60
echo
echo "########## ZONE_ID_TURNSTILE 定义 ##########"
grep -rn "ZONE_ID_TURNSTILE\|ZONE_ID_IPC_PORT" /root/star26/star-native/osfmk/kern/zalloc.h /root/star26/star-native/osfmk/kern/zalloc_internal.h 2>/dev/null | head -20
