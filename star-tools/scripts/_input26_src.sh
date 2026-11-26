#!/bin/bash
A=/root/star26/hackios-xnu-userland/userland/src/apps
ls $A | head -25
echo "=== input26 sources ==="
ls -l $A/input26* 2>/dev/null
echo "=== its log lines ==="
grep -rn 'say("input26' $A/input26*.c 2>/dev/null | head -12
</