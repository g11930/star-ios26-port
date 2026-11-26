#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/src/gfx
echo "== gfx sources =="
ls "$D" 2>/dev/null | head -20
echo
echo "== initWithAcceleratorPort in annibalemetal.m =="
grep -n "initWithAcceleratorPort" "$D"/annibalemetal.m 2>/dev/null | head
echo
echo "== context =="
L=$(grep -n "initWithAcceleratorPort" "$D"/annibalemetal.m 2>/dev/null | head -1 | cut -d: -f1)
if [ -n "$L" ]; then sed -n "$((L-8)),$((L+55))p" "$D"/annibalemetal.m; fi
