#!/bin/bash
set -u
echo "== /dev/klog support in kernel =="
grep -rn "klog" /root/star26/star-native/bsd/dev/*.c /root/star26/star-native/bsd/miscfs/*/*.c 2>/dev/null | head -10
grep -rn "\"klog\"" /root/star26/star-native/ 2>/dev/null | grep -v BUILD | head -10
echo
echo "== kern.msgbuf sysctl =="
grep -rn "msgbuf" /root/star26/star-native/bsd/kern/kern_sysctl.c 2>/dev/null | head -8
echo
echo "== EXECDBG gating (is it unconditional?) =="
grep -n "EXECDBG" /root/star26/star-native/bsd/kern/kern_exec.c | head -12
