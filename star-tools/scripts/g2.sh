#!/bin/bash
cd /root/star26 || exit 1
echo "=== dirs ==="
ls -dt s*/ 2>/dev/null | head -12
echo "=== s32 parts ==="
ls -la s32/parts 2>/dev/null
echo "=== s32 cmdline ==="
tr -d '\0' < s32/parts/cmdline 2>/dev/null; echo
echo "=== size ==="
tr -d '\0' < s32/parts/cmdline 2>/dev/null | wc -c
