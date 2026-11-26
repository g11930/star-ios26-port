#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== 文件与备份 ==="
ls -la "$F" "$F.s218-pre" 2>&1
echo "=== 行数 ==="
wc -l "$F"
echo "=== 当前是否有 s218 标记 ==="
grep -n "star_gpu_speed_tick\|star_gpu_speeds\|s218" "$F" | head -20
echo "=== md5 ==="
md5sum "$F" 2>&1
