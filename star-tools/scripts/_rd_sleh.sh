#!/bin/bash
F=/root/star26/star-native/osfmk/arm64/sleh.c
wc -l "$F"
echo "=== head 80 ==="
sed -n '1,80p' "$F"
