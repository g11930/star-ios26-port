#!/bin/bash
echo "=== 1. ipc_mqueue 结构里 msgcount/qlimit 字段定义 ==="
grep -nE "imq_msgcount|imq_qlimit|struct ipc_mqueue" /root/star26/star-native/osfmk/ipc/ipc_mqueue.h 2>/dev/null | head -30
echo
echo "=== 2. imq_full / imq_full_kernel 宏定义 ==="
grep -rn "#define imq_full\|imq_full_kernel\|imq_qlimit" /root/star26/star-native/osfmk/ipc/ipc_mqueue.h /root/star26/star-native/osfmk/ipc/ipc_port.h 2>/dev/null | head -20
echo
echo "=== 3. 字段类型（mach_port_msgcount_t 等） ==="
grep -nE "imq_msgcount|imq_qlimit" /root/star26/star-native/osfmk/ipc/ipc_mqueue.h | head
sed -n '120,175p' /root/star26/star-native/osfmk/ipc/ipc_mqueue.h 2>/dev/null
