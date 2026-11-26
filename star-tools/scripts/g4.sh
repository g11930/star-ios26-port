#!/bin/bash
cd /root/star26/star-native || exit 1
echo "=== p_wmesg in struct proc ==="
grep -rn "p_wmesg\|p_stat;" bsd/sys/proc_internal.h | head -10
echo "=== heartbeat hook ==="
grep -rn "heartbeat" --include=*.c --include=*.cpp --include=*.h . | head -20
echo "=== get_user_regs ==="
grep -rn "get_user_regs" osfmk/arm/machine/thread.h osfmk/arm/*.h 2>/dev/null | head -10
echo "=== task_threads decl ==="
grep -rn "kern_return_t.*task_threads" osfmk/kern/task.h | head -5
echo "=== proc_task ==="
grep -rn "define proc_task\|proc_task(" bsd/sys/proc_internal.h | head -5
