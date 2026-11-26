#!/bin/bash
U=/root/star26/hackios-xnu-userland/tools/mesa
echo "=== definition of rwa_texture_from_buffer ==="
grep -rn "rwa_texture_from_buffer(struct rwa_device" "$U" 2>/dev/null | head
echo
echo "=== file list of air/ ==="
ls "$U/air"
