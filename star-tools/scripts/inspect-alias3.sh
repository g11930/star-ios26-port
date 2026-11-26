#!/bin/bash
U=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== rwa_texture_from_buffer implementation ==="
grep -n "^rwa_texture_from_buffer" -A70 "$U/air_metal.c" | head -90
echo
echo "=== who calls rwa_texture_from_buffer ==="
grep -rn "rwa_texture_from_buffer" /root/star26/hackios-xnu-kernel/tools/userland-driver/ | head
