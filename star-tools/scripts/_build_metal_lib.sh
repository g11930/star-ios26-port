#!/bin/bash
B=/root/star26/hackios-xnu-userland/userland/build.sh
grep -n 'annibalemetal.m\|libannibalemetal' $B | head -10
echo "=== build invocation for the metal dylib ==="
grep -n -B4 -A10 'libannibalemetal.dylib' $B | head -40
</>
