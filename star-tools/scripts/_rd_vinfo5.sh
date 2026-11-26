#!/bin/bash
F=/root/star26/star-native/osfmk/console/video_console.c
echo "=== 2856-2884 (map flags) ==="
sed -n '2856,2884p' "$F"
echo
echo "=== flush_range / cache flush calls in video_console ==="
grep -n "flush\|Flush\|invalidate\|DC CIVAC\|cache" "$F" | head -20
