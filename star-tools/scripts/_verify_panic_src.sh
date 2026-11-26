#!/bin/bash
# 只读：定位 "unexpected exec of non-platform binary" panic 来源 + AMFI boot-arg 行为
SRC=/root/star26/star-native
wsl.exe -d Ubuntu-24.04 bash -c "
echo '=== [1] panic 字符串来源 ==='
grep -rn 'unexpected exec of non-platform binary\|non-platform binary\|userspace panic' $SRC/bsd $SRC/osfmk $SRC/libsyscall 2>/dev/null | grep -v '\.bak' | head -30
echo
echo '=== [2] amfi boot-arg 解析 (kern_codesigning.c 220-275) ==='
sed -n '220,275p' $SRC/bsd/kern/kern_codesigning.c
echo
echo '=== [3] panic 触发点上下文 (若找到) ==='
grep -rn 'userspace panic' $SRC/bsd/kern/kern_codesigning.c 2>/dev/null
" 2>/dev/null | tr -d '\r'
