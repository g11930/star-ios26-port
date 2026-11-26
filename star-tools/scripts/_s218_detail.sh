#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== [A] speeds table + vars (2308-2340) ====="
sed -n '2308,2340p' "$F"
echo
echo "===== [B] boot-arg parse (2405-2425) ====="
sed -n '2405,2425p' "$F"
echo
echo "===== [C] gpu_times (3690-3732) ====="
sed -n '3690,3732p' "$F"
echo
echo "===== [D] hfi_send signature + calls ====="
grep -n "hfi_send" "$F" | head -20
