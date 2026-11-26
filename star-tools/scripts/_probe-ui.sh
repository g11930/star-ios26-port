#!/bin/bash
set -u
D=/root/star26/hackios-xnu-kernel/xnuloader
echo "== files =="
ls -1 $D | head -30
echo
echo "== seconds counter in UI =="
grep -rn "seconds" $D/loader_06a_screen_ui.inc 2>/dev/null | head -25
echo
echo "== SILENCE_SECONDS / counter update =="
grep -rn "SILENCE_SECONDS\|%llu s\|elapsed" $D/*.inc $D/*.c 2>/dev/null | head -25
