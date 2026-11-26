#!/bin/bash
F=/mnt/c/ios26/s65-log1.bin
echo "=== 第一个 xpcproxy 加载后 40 行（看它 exec 成什么） ==="
L=$(grep -an "EXECDBG: loading /usr/libexec/xpcproxy" "$F" | head -1 | cut -d: -f1)
echo "first xpcproxy at line $L"
sed -n "${L},$((L+45))p" "$F"
echo
echo "=== xpcproxy 与其后紧跟的 EXECDBG（是否有 exec 目标服务） ==="
awk '
/EXECDBG: loading \/usr\/libexec\/xpcproxy/ {x=1; print NR": XPCLOAD"; next}
x && /EXECDBG: loading/ {print NR": THEN-EXEC "$0; x=0}
x && /xstat/ {print NR": XPC-EXIT "$0; x=0}
' "$F" | head -40
