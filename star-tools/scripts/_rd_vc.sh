#!/bin/bash
F=/root/star26/star-native/osfmk/console/video_console.c
echo "=== vc log lines with physaddr (2820-2900) ==="
sed -n '2836,2895p' "$F"
