#!/bin/bash
SRC=/root/star26/star-native
wsl.exe -d Ubuntu-24.04 bash -c "
echo '=== [1] userspace_panic / os_fatal 调用者（内核里谁报的）==='
grep -rn 'userspace_panic\|userspace panic\|os_fatal' $SRC/bsd $SRC/osfmk 2>/dev/null | grep -v '\.bak' | head -30
echo
echo '=== [2] unexpected exec 全文件系统搜（含用户态源码/测试）==='
grep -rn 'unexpected exec of non-platform\|exec of non-platform\|non-platform binary' $SRC 2>/dev/null | head -30
echo
echo '=== [3] 用户态镜像里搜这个字符串 (annibale rootfs) ==='
for d in /root/star26/star-native /mnt/c/ios26; do
  grep -rl 'unexpected exec of non-platform binary' \$d 2>/dev/null | head -5
done
" 2>/dev/null | tr -d '\r'
