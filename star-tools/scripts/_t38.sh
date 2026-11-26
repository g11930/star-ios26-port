#!/bin/bash
B=/root/star26/s111
echo "=== parts ==="; ls $B/parts
echo "=== cmdline ==="; cat $B/parts/cmdline
echo "=== tl: log writer ==="
grep -n 'tl: v\|touch_lat\|annibale_tl' /root/star26/hackios-xnu-kernel/tools/userland-driver/annibalemetal*.inc 2>/dev/null | head -8
grep -rn 'tl: v ' /root/star26/star-native --include=*.c --include=*.cpp --include=*.inc | head -5