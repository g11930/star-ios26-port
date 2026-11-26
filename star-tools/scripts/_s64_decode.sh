#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_exec.c
echo "=== spawn_no_exec / exec_done decl & set ==="
grep -n "spawn_no_exec\|exec_done" "$K" | head -40
echo
echo "=== persona flags encoding (spawn_internal.h 180-215) ==="
sed -n '180,215p' /root/star26/star-native/bsd/sys/spawn_internal.h
echo
echo "=== who calls spawn_validate_persona / where pspi_id comes from ==="
grep -n "pspi_id\|POSIX_SPAWN_PERSONA\|PSPI" /root/star26/star-native/bsd/kern/kern_exec.c | head -30
