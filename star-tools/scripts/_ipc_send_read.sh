#!/bin/bash
echo "=== 1. ipc_mqueue_send 里和 turnstile / sync / PAC 相关 ==="
grep -nE "turnstile|SEND_SYNC|imq_turnstile|ipc_mqueue_send|waitq|assert_wait|thread_block" /root/star26/star-native/osfmk/ipc/ipc_mqueue.c 2>/dev/null | head -50
echo
echo "=== 2. mach_msg2 SEND 路径关键文件 ==="
grep -rln "mach_msg2\|mach_msg_overwrite" /root/star26/star-native/osfmk/ipc/ 2>/dev/null | head -10
echo
echo "=== 3. 我们树相对官方基线在 osfmk/ipc 的改动（确认有无丢失或错误） ==="
cd /root/star26/star-native && git diff --stat ac9718f -- osfmk/ipc/ 2>/dev/null | tail -20
echo "--- 若空，用 git log 看 ipc 目录提交 ---"
git log --oneline -5 -- osfmk/ipc/ 2>/dev/null
echo
echo "=== 4. ipc_mqueue_send 是否检查 msg 接收方 turnstile 唤醒 ==="
grep -nE "waitq_wakeup|turnstile_wakeup|wakeup|clear_wait|thread_wakeup" /root/star26/star-native/osfmk/ipc/ipc_mqueue.c 2>/dev/null | head -40
