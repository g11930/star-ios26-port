#!/bin/bash
# What does softpipe do with a PIPE_BUFFER resource, and where can an 11 MB one fail?
B=/root/star-build/xnu-deps/build/mesa/mesa-25.0.7/src/gallium/drivers/softpipe
ls "$B" | head -30
echo "=== sp_screen.c: resource_create ==="
grep -n "sp_resource_create" -A28 "$B/sp_screen.c" | head -60
echo "=== allocations in sp_buffer / sp_texture ==="
grep -n "CALLOC\|MALLOC\|align_malloc\|os_malloc\|memalign" "$B/sp_buffer.c" "$B/sp_texture.c" 2>/dev/null | head -20
