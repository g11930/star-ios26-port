#!/bin/bash
K=/root/star26/hackios-xnu-kernel/tools/userland-driver
U=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== driver: buffer -> texture entry points ==="
grep -rn "offset:(NSUInteger)offset bytesPerRow" "$K"/*.inc "$K"/*.m | head -10
echo
echo "=== air: texture over buffer ==="
grep -n "rwa_texture_from_buffer\|buffer_texture_alias\|texture_alias" "$U/air_metal.c" "$U/air_metal.h" | head -20
