#!/bin/bash
F=/root/star26/star-native/osfmk/arm64/sleh.c
echo "=== 1225-1300 ==="
sed -n '1225,1300p' "$F"
echo
echo "=== 1400-1475 (dispatch site) ==="
sed -n '1400,1475p' "$F"
