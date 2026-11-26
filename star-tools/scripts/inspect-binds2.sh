#!/bin/bash
A=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== all bind assignments in air sources ==="
grep -rn "PIPE_BIND_SHARED\|PIPE_BIND_DISPLAY_TARGET\|PIPE_BIND_SCANOUT" "$A" | head -20
echo
echo "=== static texture_of_shape body (first 90 lines from its definition) ==="
n=$(grep -n "^texture_of_shape" "$A/air_metal_texture.inc" | head -1 | cut -d: -f1)
echo "defined at line $n"
sed -n "$((n-40)),$((n+90))p" "$A/air_metal_texture.inc"
