#!/bin/bash
X=/root/star26/hackios-xnu-kernel/xnuloader
echo "=== read_key_stroke call sites ==="
grep -rn "read_key_stroke\|con_in\|simple_text_input" $X/*.inc | head -20

echo
echo "=== menu loop (820-1000) ==="
sed -n '820,1000p' $X/loader_06a_screen_ui.inc

echo
echo "=== line count screen_ui ==="
wc -l $X/loader_06a_screen_ui.inc
