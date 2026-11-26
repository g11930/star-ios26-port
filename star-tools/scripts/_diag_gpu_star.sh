#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== file ==="
ls -la "$F"
wc -l "$F"
echo
echo "=== first 80 lines ==="
head -80 "$F"
echo
echo "=== stage / boot-arg markers ==="
grep -n -E "stage|adreno_stage|boot_arg|PE_parse_boot_argn|stage_num|STAGE" "$F" | head -60
