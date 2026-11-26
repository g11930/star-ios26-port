#!/bin/bash
# 只读：核查我们 dyld_shared_cache 的格式，为移植 zeta 重写工具做兼容性判断
echo "===== 1. cache 文件清单 ====="
ls -lah /root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld/ 2>/dev/null

echo ""
echo "===== 2. cache 文件大小与 file 类型 ====="
for f in /root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.*; do
  echo "--- $(basename $f) ---"
  ls -l "$f" 2>/dev/null | awk '{print $5, $9}'
  file "$f" 2>/dev/null
done

echo ""
echo "===== 3. cache header 魔数与版本 (前 64 字节 hex) ====="
for f in /root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.*; do
  echo "--- $(basename $f) ---"
  xxd -l 64 "$f" 2>/dev/null
done

echo ""
echo "===== 4. 关键结构偏移 probing (magic / slideInfo version / subtype) ====="
python3 - <<'PY'
import glob, struct, os
files = glob.glob('/root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.*')
for f in files:
    print('---', os.path.basename(f), '---')
    with open(f,'rb') as fh:
        data = fh.read(4096)
    magic = data[:16]
    print('magic:', magic)
    # dyld_shared_cache header (dyld_cache_header) fields, little endian
    # uint32 magicOffset 0; uint32 cputype 4; uint32 cpusubtype 8; uint32 filesCount 12
    if len(data) >= 16:
        cputype, cpusubtype, filesCount = struct.unpack_from('<III', data, 4)
        print('cputype=0x%x cpusubtype=0x%x files=%d' % (cputype, cpusubtype, filesCount))
    # slideInfo offsets are at various header offsets depending on version; scan for version words
    # print first 96 words as u32 to eyeball
    words = struct.unpack_from('<24I', data, 0)
    print('first 24 u32:', ' '.join('0x%x'%w for w in words))
PY

echo ""
echo "===== 5. 找系统里可用的 python 依赖 ====="
python3 -c 'import capstone; print("capstone", capstone.__version__)' 2>&1
python3 -c 'import lief; print("lief", lief.__version__)' 2>&1
which llvm-mc 2>/dev/null || echo "llvm-mc NOT in PATH"
