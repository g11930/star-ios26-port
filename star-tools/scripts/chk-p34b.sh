#!/bin/bash
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== 文件 ==="
ls -l "$K"
echo "=== otool 头 ==="
llvm-otool-18 -hv "$K" 2>&1 | head -8
echo "=== 段 ==="
llvm-otool-18 -l "$K" 2>&1 | grep -E 'segname|fileoff|filesize' | head -30
echo "=== 末尾 64 字节 ==="
tail -c 64 "$K" | od -An -tx1 | head -4
echo "=== 对比 P33 载荷里的 kernel ==="
cd /tmp && rm -rf p33x && mkdir p33x && cd p33x && python3 - <<'PY'
import struct
p = open('/mnt/c/ios26/p33-payload.bin','rb').read()
print('payload head:', p[:8], 'size', len(p))
PY
