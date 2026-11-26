#!/bin/bash
echo "=== 1. ipc_mqueue 结构（消息链表字段） ==="
sed -n '83,120p' /root/star26/star-native/osfmk/ipc/ipc_mqueue.h
echo
echo "=== 2. ipc_kmsg 如何取 header / 遍历队列 ==="
grep -nE "imq_messages|ikm_prev|ikm_next|ikm_header|TAILQ_FIRST|FIRST_IN_QUEUE|ipc_kmsg_get" /root/star26/star-native/osfmk/ipc/ipc_mqueue.c 2>/dev/null | head -30
echo
echo "=== 3. ipc_kmsg.h 里 header 访问宏 ==="
grep -nE "#define ikm_header|ikm_header\(|struct mach_msg_header" /root/star26/star-native/osfmk/ipc/ipc_kmsg.h 2>/dev/null | head -15
echo
echo "=== 4. mach_msg_header 的 msgh_id / bits 字段 ==="
grep -rnE "msgh_id|msgh_bits|msgh_remote_port|msgh_local_port" /root/star26/star-native/osfmk/mach/message.h 2>/dev/null | head -15
