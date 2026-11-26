#!/bin/bash
K=/root/star26/star-native
echo "=== where the volume role/UUID text comes from ==="
grep -rn "published volume" $K/bsd --include='*.c' --include='*.inc' | head -5
grep -rn "Role " $K/bsd/dev/star/*.c $K/bsd/dev/star/*.inc 2>/dev/null | head -10
echo "=== a Role property ==="
grep -rn "\"Role\"" $K/bsd/dev/star/ 2>/dev/null | head -10
echo "=== uuid in disk publication ==="
grep -rn "uuid" $K/bsd/dev/star/annibale_disk_nodes.inc | head -10
