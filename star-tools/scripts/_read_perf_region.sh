#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
sed -n '2300,2400p' "$F"
echo "=================== core_khz users ==================="
grep -n "core_khz" "$F"
echo "=================== perf struct decl ==================="
grep -n -B3 -A12 "struct hfi_perf_table {" "$F"
