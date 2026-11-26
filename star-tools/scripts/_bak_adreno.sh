#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
cp -p "$F" "$F.s218-pre"
echo "=== backup ==="
md5sum "$F" "$F.s218-pre"
echo "=== lines ==="
wc -l "$F" "$F.s218-pre"
