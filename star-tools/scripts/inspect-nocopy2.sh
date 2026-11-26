#!/bin/bash
K=/root/star26/hackios-xnu-kernel/tools/userland-driver
U=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== where newBufferWithBytesNoCopy lives ==="
grep -rn "newBufferWithBytesNoCopy" "$K" | head
echo
echo "=== rwa_buffer_create decl + doc ==="
grep -n "rwa_buffer_create" -B30 "$U/air_metal.h" | sed -n '1,60p'
