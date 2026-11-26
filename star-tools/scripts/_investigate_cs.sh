#!/bin/bash
# 只读核实：CS 强制关闭的可行路径 + non-platform 来源 + 已有 CS 补丁
SRC=/root/star26/star-native
wsl.exe -d Ubuntu-24.04 bash -c "
echo '=== [1] kern_codesigning.c 开头 config 初始化（RELEASE 生效段 100-165）==='
sed -n '100,170p' $SRC/bsd/kern/kern_codesigning.c
echo
echo '=== [2] CS_CONFIG 宏定义 ==='
grep -rn 'define CS_CONFIG_ALLOW_ANY_SIGNATURE\|define CS_CONFIG_ENFORCEMENT_DISABLED\|define CS_CONFIG_GET_OUT_OF_MY_WAY\|define CS_CONFIG_INVALID' $SRC/osfmk $SRC/bsd 2>/dev/null | head -20
echo
echo '=== [3] 已有 star_cs / CS 相关内核补丁（全树搜）==='
grep -rn 'star_cs\|cs_keep_valid\|keep_valid' $SRC/osfmk $SRC/bsd 2>/dev/null | grep -v '\.bak' | head -30
echo
echo '=== [4] unexpected exec of non-platform binary 字符串全树 ==='
grep -rn 'unexpected exec\|non-platform binary\|not a platform binary' $SRC 2>/dev/null | grep -v '\.bak' | head -20
" 2>/dev/null | tr -d '\r'
