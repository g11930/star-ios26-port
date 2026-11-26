#!/bin/bash
cd /root/star26/star-native || exit 1
echo "=== p_wmesg context ==="
sed -n '650,700p' bsd/sys/proc_internal.h
echo "=== who sets p_wmesg ==="
grep -rn "p_wmesg" --include=*.c --include=*.h bsd osfmk | head -20
echo "=== task from proc ==="
grep -rn "proc_task\b" bsd/sys/*.h | head -10
echo "=== loader_return heartbeat loop ==="
sed -n '820,860p' osfmk/arm64/loader_return.c
