#!/bin/bash
D=/root/dsc26/System/Library/Caches/com.apple.dyld
echo "=== 0 字节或异常小的分片 ==="
find "$D" -maxdepth 1 -name "dyld_shared_cache_arm64e*" -size -1k -printf "%s %f\n" 2>/dev/null | sort -n | head -20
echo
echo "=== 分片总数 ==="
find "$D" -maxdepth 1 -name "dyld_shared_cache_arm64e*" | wc -l
echo "=== 总大小 ==="
du -sh "$D"
echo
echo "=== 主文件 subcache 表里的所有 suffix 对应文件大小 ==="
python3 - <<'PY'
import struct, os
MAIN='/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e'
with open(MAIN,'rb') as f:
    h=f.read(0x60000)
off,cnt=struct.unpack_from('<II',h,0x188)
print('subcache count:',cnt)
for i in range(cnt):
    e=off+56*i
    suf=h[e+24:e+56].split(b'\0',1)[0].decode()
    p=MAIN+suf
    sz=os.path.getsize(p) if os.path.exists(p) else -1
    if sz < 1024:
        print('  SMALL/EMPTY idx=%d suffix=%r size=%d' % (i, suf, sz))
PY
