#!/bin/bash
U=/root/star26/s111/work/rootbuild/root
K=/root/star26/star-native
P=/root/star26/s111/parts

echo "=== rc.jobs 现在的内容 ==="
cat "$U/etc/rc.jobs" 2>/dev/null
echo
echo "=== etc 目录下的备份 ==="
ls -la "$U/etc/" 2>/dev/null | grep -iE "rc.jobs|\.bak" | head -20

echo
echo "=== 用户态树最近 14 小时内改过的文件（前 25 个）==="
find "$U" -type f -newermt '-14 hours' 2>/dev/null | head -25

echo
echo "=== 内核树 git 状态 ==="
cd "$K" 2>/dev/null && (git status --short 2>/dev/null | head -20; echo "--- HEAD ---"; git log --oneline -5 2>/dev/null) || echo "(不是 git 仓库或无权限)"

echo
echo "=== 内核树里的 .bak（最近的 20 个）==="
find /root/star26/star-native -name "*.bak" -newermt '-2 days' 2>/dev/null | head -20

echo
echo "=== 当前 cmdline ==="
cat "$P/cmdline" 2>/dev/null
echo
echo "=== s173 与 s174 部件 md5 对比 ==="
md5sum "$P/kernel" "$P/ramdisk" "$P/loader.efi" 2>/dev/null
echo "--- s173 / s174 镜像 ---"
ls -la /mnt/c/ios26/s173-boot.img /mnt/c/ios26/s174-boot.img 2>/dev/null
md5sum /mnt/c/ios26/s173-boot.img /mnt/c/ios26/s174-boot.img 2>/dev/null
