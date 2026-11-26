#!/bin/bash
F=/root/star26/star-native/osfmk/console/video_console.c
echo "=== 2880-2960 ==="
sed -n '2880,2960p' "$F"
