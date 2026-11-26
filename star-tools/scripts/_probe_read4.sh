#!/bin/bash
echo "########## turnstile.c 210-250（proprietor 当 port 用的上下文） ##########"
sed -n '210,250p' /root/star26/star-native/osfmk/kern/turnstile.c
echo
echo "########## 类型/状态读取宏 ##########"
grep -nE "define turnstile_type|turnstile_get_type|ts_type_gencount|TURNSTILE_TYPE|ts_state|turnstile_state" /root/star26/star-native/osfmk/kern/turnstile.h | head -40
echo
echo "########## turnstile.h 类型位操作 60-80 ##########"
sed -n '55,80p' /root/star26/star-native/osfmk/kern/turnstile.h
echo
echo "########## waitq type: WQT_TURNSTILE ##########"
grep -rn "WQT_TURNSTILE\|waitq_type\|waitq_get_type\|waitq.wq_type" /root/star26/star-native/osfmk/kern/waitq.h 2>/dev/null | head -20
