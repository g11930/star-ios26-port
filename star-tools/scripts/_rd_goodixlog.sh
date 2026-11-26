#!/bin/bash
R=/root/star26/star-native
echo "=== goodix logging impl (lines 45-80) ==="
sed -n '45,80p' "$R/bsd/dev/star/annibale_goodix.c"
echo
echo "=== libkern.h 185-205 ==="
sed -n '185,205p' "$R/bsd/libkern/libkern.h"
echo
echo "=== star_platform_stubs.c 65-90 ==="
sed -n '65,90p' "$R/bsd/dev/star/star_platform_stubs.c"
