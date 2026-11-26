#!/bin/bash
U=/root/star26/hackios-xnu-userland/tools/mesa/air
K=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== rwa buffer APIs in air_metal.h ==="
grep -n "rwa_buffer" "$U/air_metal.h" | head -30
echo
echo "=== driver newBufferWithBytesNoCopy ==="
grep -n "newBufferWithBytesNoCopy" -A45 "$K/annibalemetal_buffer_pipeline.inc" | head -70
