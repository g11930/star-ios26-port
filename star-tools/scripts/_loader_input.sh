#!/bin/bash
X=/root/star26/hackios-xnu-kernel/xnuloader
echo "=== interaction / key handling ==="
grep -rn "user_interacted\|key\|button\|volume\|vol_up\|vol_down\|gpio\|con_in\|ConIn" $X/*.inc $X/loader.c 2>/dev/null | grep -viE "kext|keybag|keyboard layout" | head -30

echo
echo "=== menu block (screen_ui 540-640) ==="
sed -n '540,660p' $X/loader_06a_screen_ui.inc

echo
echo "=== ui_tick (300-352) ==="
sed -n '300,352p' $X/loader_06a_screen_ui.inc
