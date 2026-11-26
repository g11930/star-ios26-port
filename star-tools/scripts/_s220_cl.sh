#!/bin/bash
echo "=== s207/cmdline 原始(带尾部) ==="
xxd /root/star26/baseline/s207parts/cmdline 2>/dev/null | tail -6
echo "len=$(tr -d '\0' < /root/star26/baseline/s207parts/cmdline | wc -c)"
echo
echo "=== 从 s217-boot.img 读出 cmdline (权威) ==="
python3 /mnt/d/桌面/star26-deps/scripts/xnup_info.py /mnt/c/ios26/s217-boot.img 2>&1 | head -40
echo
echo "=== 定位 cmdline 尾部 pac_patch ==="
tr -d '\0' < /root/star26/baseline/s207parts/cmdline | grep -o 'pac_patch=[0-9]*'
