#!/bin/bash
T=/root/star26/star-native
F=$T/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== A. 备份与当前文件时间/大小 ==="
ls -l $F $T/iokit/Kernel/MiniFramebufferUserClient.inc.*.bak 2>&1
echo
echo "=== B. 当前文件里 Accelerator 相关行 ==="
grep -n 'Accelerator\|setProperty\|metal\|Metal\|sgx\|SGX' $F | head -60
echo
echo "=== C. 与 s91 备份的 diff 摘要 ==="
if [ -f "$F.s91.bak" ]; then diff -u "$F.s91.bak" "$F" | head -120; else echo "no s91 bak"; fi
echo
echo "=== D. 与 s90 备份的 diff 摘要 ==="
if [ -f "$F.s90.bak" ]; then diff -u "$F.s90.bak" "$F" | head -60; else echo "no s90 bak"; fi
echo "=== DONE ==="
