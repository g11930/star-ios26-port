#!/bin/bash
F=/root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal.m
echo "== AnnibaleGPU references =="
grep -n "AnnibaleGPU" "$F" | head -12
echo
echo "== impl of initWithAcceleratorPort (line numbers) =="
grep -n "initWithAcceleratorPort" "$F" | sed -n '2,8p'
echo
L=$(grep -n "initWithAcceleratorPort" "$F" | sed -n '3p' | cut -d: -f1)
echo "== third hit line=$L, show 60 lines around =="
if [ -n "$L" ]; then awk -v s="$L" 'NR>=s-6 && NR<=s+58' "$F"; fi
