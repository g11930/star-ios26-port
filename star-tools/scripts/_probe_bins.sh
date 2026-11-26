#!/bin/bash
R=/root/star26/s48/work/root
echo "== test binaries in /bin =="
ls -l "$R"/bin/ 2>/dev/null | awk '{print $5, $9}' | head -40
