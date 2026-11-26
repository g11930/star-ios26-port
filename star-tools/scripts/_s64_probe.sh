#!/bin/bash
F=/mnt/c/ios26/s64-fresh6.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== StarMsgProbe 全部输出 ==="
grep -a "StarMsgProbe" "$F" | head -160
