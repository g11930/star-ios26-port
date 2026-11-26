#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== 3680..3770 (busy count, submit) ====="
sed -n '3680,3770p' "$F"
