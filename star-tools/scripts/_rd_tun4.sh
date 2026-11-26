#!/bin/bash
R=/root/star26/star-native
grep -rn "__TUNABLE" "$R/osfmk/kern/startup.h" | head
echo "=== body ==="
awk '/#define __TUNABLE\(/,/^$/' "$R/osfmk/kern/startup.h" | head -40
echo "=== __TUNABLE_STR etc ==="
sed -n "$(grep -n '#define __TUNABLE(' "$R/osfmk/kern/startup.h" | cut -d: -f1),+30p" "$R/osfmk/kern/startup.h"
