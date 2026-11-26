#!/bin/bash
D=/root/star26/star-native/bsd/dev/star
F=$D/annibale_goodix.c
echo "=== fw header needed by transplanted file ==="
grep -n '#include ".*focaltech_fw.h"' "$F"
echo "--- available in star dir ---"
ls "$D"/*focaltech_fw.h 2>/dev/null
echo
echo "=== loader_log_line / annibale_tl / redwood_tl refs ==="
grep -nE "loader_log_line|annibale_tl|redwood_tl|loader_log_putc" "$F" | head -20
echo
echo "=== annibale_input.h API present? ==="
grep -nE "ANNIBALE_TOUCH_(DOWN|MOVE|UP)|annibale_touch_post" /root/star26/star-native/bsd/sys/annibale_input.h | head -10
echo
echo "=== init function + who calls it ==="
grep -n "annibale_goodix_init" "$F"
grep -rn "annibale_goodix_init" /root/star26/star-native/bsd --include=*.c | grep -v annibale_goodix.c | head -5
