#!/bin/bash
X=/root/star26/hackios-xnu-kernel/xnuloader
echo "=== menu items ==="
sed -n '340,430p' $X/loader_06a_screen_ui.inc

echo
echo "=== spmi button read + menu loop ==="
sed -n '650,820p' $X/loader_06a_screen_ui.inc

echo
echo "=== oem stage / write commands in usb entry ==="
sed -n '780,830p' $X/loader_06_usb_entry.inc
