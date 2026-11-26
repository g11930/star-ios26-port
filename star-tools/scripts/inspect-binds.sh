#!/bin/bash
A=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== texture_of_shape: bind computation ==="
grep -n "texture_of_shape" -A90 "$A/air_metal_texture.inc" | sed -n '1,120p'
