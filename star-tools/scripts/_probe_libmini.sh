#!/bin/bash
M=/root/star26/hackios-xnu-userland/userland/libmini
echo "== libmini files =="
ls "$M" | head -20
echo "== stat / lstat / fstat in libmini =="
grep -rn "stat\b\|struct stat\|stat(" "$M"/*.h "$M"/*.c 2>/dev/null | head -15
echo "== readdir support =="
grep -rn "readdir\|dirent" "$M"/*.h "$M"/*.c 2>/dev/null | head -10
