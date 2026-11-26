#!/bin/bash
A=/root/star26/hackios-xnu-userland/tools/mesa/air
echo "=== where rwa_buffer_from_memory is defined ==="
grep -rn "rwa_buffer_from_memory" "$A" | head
echo
echo "=== body ==="
grep -rn "^rwa_buffer_from_memory" -A60 "$A"/*.inc "$A"/*.c 2>/dev/null | head -80
