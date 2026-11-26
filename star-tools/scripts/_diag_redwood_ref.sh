#!/bin/bash
R=/root/star26/warsaw-ref/xnu/files/bsd/dev/redwood_adreno.c
echo "=== ref file ==="
ls -la "$R" 2>/dev/null && wc -l "$R"
echo
echo "=== ref: speeds[] and bw table ==="
grep -n -A30 "speeds\[\] = \|struct hfi_bw_table bw" "$R" 2>/dev/null | head -80
echo
echo "=== ref: any per-level bw table / ddr_data fill ==="
grep -n "ddr_data\|bw.levels\|gpu_levels = \|HFI_GX_BW_PERF_VOTE" "$R" 2>/dev/null | head -30
echo
echo "=== ref: speed tick / on-demand ==="
grep -n -i "tick\|permille\|busy\|set_freq\|freq_vote" "$R" 2>/dev/null | head -30
