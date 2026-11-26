#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "== IOServiceMatching across driver =="
grep -rn "IOServiceMatching" "$D" 2>/dev/null | head -12
echo
echo "== head of annibalemetal.m (1-60) =="
sed -n '1,60p' "$D"/annibalemetal.m
