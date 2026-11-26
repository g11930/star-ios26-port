#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/services/input26_service.c
grep -n "touch_mode\|TOUCH_MODE_WAKE\|ANN_FINGER_WAKE_SWALLOWED" "$F"
echo "=== headings ==="
sed -n '470,560p' "$F"
