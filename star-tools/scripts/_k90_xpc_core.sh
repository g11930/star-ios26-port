#!/bin/bash
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
echo "=== K90 XPC shim 800-1010 ==="
sed -n '800,1010p' "$K"
