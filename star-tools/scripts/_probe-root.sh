#!/bin/bash
set -u
ROOT=/root/star26/s41/work/root
echo "== top level =="
ls -1 $ROOT | head -40
echo
echo "== depth2 =="
find $ROOT -maxdepth 2 -type d 2>/dev/null | head -60
echo
echo "== AnnibaleMetal.bundle =="
find $ROOT/lib/AnnibaleMetal.bundle -maxdepth 3 2>/dev/null | head -20
echo
echo "== files mentioning 'AnnibaleGPU' =="
grep -rl "AnnibaleGPU" $ROOT 2>/dev/null | head
echo
echo "== part files =="
ls -1 /root/star26/s41/parts 2>/dev/null | head -20
