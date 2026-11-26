#!/bash
echo "=== 找 IOMobileFramebuffer.framework 二进制 ==="
find /root -maxdepth 6 -name "IOMobileFramebuffer" -type f 2>/dev/null | head -10
echo "=== sys-root 结构 ==="
ls /root/sys-root 2>/dev/null | head
find /root/sys-root -maxdepth 4 -name "*IOMobileFramebuffer*" 2>/dev/null | head -5
echo "=== dsc 目录 ==="
ls /root/dsc26/System/Library/PrivateFrameworks 2>/dev/null | grep -i mobileframe
