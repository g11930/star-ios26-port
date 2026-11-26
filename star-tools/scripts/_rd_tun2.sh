#!/bin/bash
sed -n '230,320p' /root/star26/star-native/osfmk/kern/startup.h
echo "=== PE_parse_boot_argn behavior for PE_no_debug ==="
grep -rn "PE_parse_boot_argn\b" /root/star26/star-native/pexpert/gen/pe_gen.c 2>/dev/null | head -5
