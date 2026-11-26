#!/bin/bash
K=/root/star26/k90ref/kernel/xnu26/patches/44-osfmk%arm64%sleh.c.patch
echo "=== K90 sleh.c.patch 全文 ==="
wc -l "$K"
cat "$K"
echo
echo "=== K90 annibale_threads.c 里 PAC 相关 ==="
grep -n -i -E 'pac|ptrauth|auth' /root/star26/k90ref/kernel/xnu/files/bsd/dev/annibale/annibale_threads.c 2>/dev/null | head -20
