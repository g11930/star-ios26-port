#!/bin/bash
X=/root/star26/hackios-xnu-kernel/xnuloader
echo "=== partwrite / part_write ==="
grep -rn "partwrite\|part_write" $X/*.inc $X/loader.c 2>/dev/null | head -12

echo
echo "=== screen ui: function definitions ==="
grep -nE "^[a-z_][a-z0-9_]*\(|^static [a-z].*\(" $X/loader_06a_screen_ui.inc 2>/dev/null | head -30

echo
echo "=== usb entry: command dispatch ==="
grep -n "oem \|starts_with" $X/loader_06_usb_entry.inc 2>/dev/null | head -30

echo
echo "=== loader.c: what it includes ==="
grep -n "#include" $X/loader.c

echo
echo "=== newest images + any s97-s99 scripts ==="
ls -la /mnt/c/ios26/*.img | tail -6
ls -lat /mnt/d/桌面/star26-deps/scripts/*s9*.sh 2>/dev/null | head -10
