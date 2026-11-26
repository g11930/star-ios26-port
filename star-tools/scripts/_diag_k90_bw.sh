#!/bin/bash
F=/root/star26/kbuild/xnu-12377.121.6/bsd/dev/adreno8/adreno8_hfi.c
echo "=== bw table struct + builder ==="
grep -n -A60 "build_bw_table" "$F" | head -120
echo
echo "=== ddr_data packing / vote format ==="
grep -n -B4 -A12 "ddr_data\[" "$F" | head -80
