#!/bin/bash
R=/root/star26/star-native
F=$R/osfmk/console/video_console.c
echo "=== vinfo assignments (word boundary) ==="
grep -n "vinfo" "$F" | grep -E "vinfo\.v_[a-z]+ *=" | head -20
echo
echo "=== PE_state / initialize_screen ==="
grep -n "PE_state\|initialize_screen\|video_init" "$F" | head -20
echo
echo "=== initialize_screen body ==="
sed -n "$(grep -n '^initialize_screen' "$F" | cut -d: -f1),+70p" "$F"
