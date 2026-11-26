#!/bin/bash
echo "=== 1. imq_receiver_name 字段（已知在 ipc_mqueue.h:85） ==="
grep -n "imq_receiver_name" /root/star26/star-native/osfmk/ipc/ipc_mqueue.h /root/star26/star-native/osfmk/ipc/*.c 2>/dev/null | head -15
echo
echo "=== 2. launchd rcv name 来源：探针 regs[2]=x4 ==="
grep -n "regs\[2\]\|x4\|rcv=" /root/star26/star-native/bsd/dev/star/star_msgprobe.c | head -15
echo
echo "=== 3. 结构当前字段 ==="
sed -n '32,52p' /root/star26/star-native/osfmk/kern/star_msgprobe_k.c
echo
echo "=== 4. 打印 launchd 线程处（能否加 receiver_name） ==="
grep -n "not mach_msg-looking\|mach_msg opt\|rcv=%llx\|regs\[2\]" /root/star26/star-native/bsd/dev/star/star_msgprobe.c | head -20
