#!/bin/bash
R=/root/star26/star-native
echo "=== CONFIG_NO_PRINTF_STRINGS in config ==="
grep -rn "CONFIG_NO_PRINTF_STRINGS" "$R" 2>/dev/null | grep -v "\.bak" | head -10
echo
echo "=== printf macro definition ==="
grep -rn "define printf\|define kprintf" "$R/osfmk/kern/printf.h" "$R/bsd/sys/systm.h" "$R/libkern/libkern.h" 2>/dev/null | head -10
echo
echo "=== how goodix logs (IOLog or loader_log) ==="
grep -n "IOLog\|loader_log_putc" "$R/bsd/dev/star/annibale_goodix.c" | head -5
echo
echo "=== build config files ==="
ls -l "$R/BUILD/"*/obj/RELEASE_ARM64*/*.release 2>/dev/null | head -3
find "$R" -name "*.release" -newermt "-30 days" 2>/dev/null | head -3
