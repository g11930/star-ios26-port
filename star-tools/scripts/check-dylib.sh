#!/bin/bash
L=/mnt/d/桌面/star26-deps/release/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
echo "=== size ==="
ls -la "$L"
echo "=== client-memory string count ==="
strings "$L" | grep -c 'client-memory copy allocation failed'
echo "=== drawable strings present ==="
strings "$L" | grep -i 'no drawable\|no connection to AnnibaleGPU\|annibaledrawable:' | head -10
echo "=== surface plane copy string ==="
strings "$L" | grep -c 'surface plane %lu copy allocation failed'
