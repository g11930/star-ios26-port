#!/bin/bash
M=/root/star-build/xnu-deps/build/mesa/mesa-25.0.7
echo "=== sp_texture.c 60-130 (align_malloc site) ==="
sed -n '60,130p' "$M/src/gallium/drivers/softpipe/sp_texture.c"
echo "=== sp_texture.c 150-240 (create entry points) ==="
sed -n '150,240p' "$M/src/gallium/drivers/softpipe/sp_texture.c"
echo "=== pipe_buffer_create definition ==="
grep -rn "^pipe_buffer_create" -A40 "$M/src/gallium/auxiliary/util/" 2>/dev/null | head -60
