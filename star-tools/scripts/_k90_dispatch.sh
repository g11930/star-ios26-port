#!/bin/bash
K=/root/ref2/annibale-kernel/xnu/files/bsd/dev/annibale/annibale_gpu_dispatch.c
echo "===== K90 annibale_gpu_dispatch.c 行数 ====="
wc -l "$K"
echo
echo "===== 完整读（重点 100-260 行）====="
sed -n '1,260p' "$K"
