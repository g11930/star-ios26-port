#!/bin/bash
echo "=== /root/ref 下的参考仓库 ==="
ls -la /root/ref/ 2>/dev/null
echo
echo "=== dada.patch 改了哪些文件（全集） ==="
grep "^diff --git" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch 2>/dev/null | sed 's#diff --git a/##; s# b/.*##' | head -100
echo
echo "=== dada.patch 文件总数 ==="
grep -c "^diff --git" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch 2>/dev/null
echo
echo "=== warsaw xnu 补丁全集 ==="
ls /root/ref/warsaw/xnu/patches/ 2>/dev/null
echo
echo "=== 参考仓库里的 docs ==="
find /root/ref -maxdepth 3 -type d -name docs 2>/dev/null
find /root/ref -maxdepth 4 -type f \( -name "*.md" -o -name "*.txt" \) 2>/dev/null | head -40
