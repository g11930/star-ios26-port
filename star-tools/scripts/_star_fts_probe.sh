#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "=== focaltech funcs in star version ==="
grep -nE "focaltech_probe|focaltech_read_boot_id|focaltech_enter_boot_rom|focaltech_write_pram|focaltech_start_app|FOCALTECH_FW_LENGTH|focaltech_fw|focaltech_wait_valid|PRAM|download" "$S" | head -40
echo
echo "=== bring_up ==="
grep -n "bring_up\|no focaltech\|serial engine\|trying the pins\|selected " "$S" | head -20
echo
echo "=== fw header file present? ==="
ls -la /root/star26/star-native/bsd/dev/star/*focaltech* 2>/dev/null || echo "NO focaltech fw header in star tree"
