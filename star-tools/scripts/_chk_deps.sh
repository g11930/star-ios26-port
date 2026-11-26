#!/bin/bash
R=/root/star26/star-native
echo "=== annibale_input in files ==="
grep -rn "annibale_input" "$R/bsd/conf/files" 2>/dev/null
echo "=== existing .o ==="
find "$R/BUILD" -name "annibale_input.o" -o -name "annibale_input.cpo" 2>/dev/null | head
echo "=== mtimes ==="
ls -l "$R/bsd/dev/star/annibale_input.c"
find "$R/BUILD" -name "annibale_input.o" -exec ls -l {} \; 2>/dev/null
echo "=== current kernel ==="
ls -l "$R/BUILD/obj/RELEASE_ARM64_BCM2837/kernel.release" 2>/dev/null
md5sum "$R/BUILD/obj/RELEASE_ARM64_BCM2837/kernel.release" 2>/dev/null
