#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== [A] perf/bw table build (2240-2420) ==="
sed -n '2240,2420p' "$F"
echo
echo "=== [B] bw table struct + ddr levels ==="
sed -n '2110,2240p' "$F"
