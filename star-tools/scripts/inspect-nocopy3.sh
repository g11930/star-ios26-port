#!/bin/bash
K=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== mesa.buffer_* uses in driver ==="
grep -rn "mesa\.buffer_" "$K" | head -20
echo
echo "=== mirror init ==="
grep -n "initWithDevice:(AnnibaleMetalDevice \*)device" -A6 "$K/annibalemetal_buffer_pipeline.inc" | sed -n '1,80p'
