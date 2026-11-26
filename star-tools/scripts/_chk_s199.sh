#!/bin/bash
B=/root/star26/baseline/s199parts
ls -l "$B" 2>/dev/null
echo "=== md5 ==="
md5sum "$B"/* 2>/dev/null
echo "=== cmdline ==="
tr -d '\0' < "$B/cmdline" 2>/dev/null
echo
echo "bytes: $(tr -d '\0' < "$B/cmdline" 2>/dev/null | wc -c)"
