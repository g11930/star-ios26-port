#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_exec.c
echo "=== spawn_validate_persona full ==="
awk '/^spawn_validate_persona/,/^}/' "$K" | head -80
echo
echo "=== spawn_persona_adopt full ==="
awk '/^spawn_persona_adopt/,/^}/' "$K" | head -100
echo
echo "=== spawn.h persona flags ==="
grep -n "POSIX_SPAWN_PERSONA" /root/star26/star-native/bsd/sys/spawn.h | head -30
echo
echo "=== spawn_internal.h ==="
find /root/star26 -name "spawn_internal.h" 2>/dev/null | head -5
grep -rn "POSIX_SPAWN_PERSONA_TYPE_SHIFT\|PERSONA_FLAGS_OVERRIDE\|PERSONA_FLAGS_VERIFY" /root/star26/star-native/bsd/ 2>/dev/null | head -20
