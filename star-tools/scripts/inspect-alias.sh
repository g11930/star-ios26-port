#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== air_metal.c: buffer_texture_alias ==="
grep -n "buffer_texture_alias" -A60 "$U/tools/mesa/air/air_metal.c" | head -90
echo
echo "=== driver: newTextureWithDescriptor:offset:bytesPerRow: ==="
grep -rn "newTextureWithDescriptor:(MTLTextureDescriptor \*)d offset" -A45 "$U/../hackios-xnu-kernel/tools/userland-driver/annibalemetal_buffer_pipeline.inc" | head -70
