#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/star_display_handoff.c
wc -l "$F"
echo "=== body 60-200 ==="
sed -n '60,200p' "$F"
