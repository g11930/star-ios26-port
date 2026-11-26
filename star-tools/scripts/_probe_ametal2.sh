#!/bin/bash
F=/root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal.m
echo "== size =="
wc -l "$F"
echo "== initWithAcceleratorPort =="
grep -n "initWithAcceleratorPort\|AnnibaleMetalDevice.*init\|- (instancetype)init" "$F" | head -12
echo
L=$(grep -n "initWithAcceleratorPort" "$F" | head -1 | cut -d: -f1)
echo "== context around $L =="
if [ -n "$L" ]; then sed -n "$((L-20)),$((L+70))p" "$F"; fi
