#!/bin/bash
echo "=== K90 树里 ptrauth / PAuth / PAC 硬件相关 (全部 patch + 源文件) ==="
cd /root/star26/k90ref/kernel
grep -rn -i -E 'ptrauth|FEAT_PAuth|paciasp|pacibsp|autiasp|PAuth|arm64e|ARM64E|CPU.*ARMv9|ORYON|Oryon|SM8750' xnu26/patches xnu/files 2>/dev/null | grep -v -E '^\s*$' | head -50
echo
echo "=== K90 xnu26 patch 列表 (看有没有 PAC 相关 patch) ==="
cat xnu26/patches/series 2>/dev/null | head -60
echo
echo "=== K90 编译配置里的 march / ptrauth flag ==="
grep -rn -E 'march=|arm64e|ptrauth|PTR AUTH|CONFIG_PTRAUTH|ARM64E_PTRAUTH' xnu26/*.sh xnu26/*.mk xnu26/Makefile* xnu/*.sh xnu/Makefile* 2>/dev/null | head -30
