#!/usr/bin/env python3
"""只读：解析 dyld_shared_cache header 的 mapping slide info，确认 slide info 版本。
结构来自 dyld_cache_format.h，与 zeta_dyld_cache.py 的 HEADER_* 常量一致。"""
import struct, glob, os

MAPPINGS = 0x10
SLIDE = 0x138
SUBCACHES = 0x188
IMAGES = 0x1c0
SUBCACHE_ENTRY = 56

for f in sorted(glob.glob('/root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e.*')):
    print('=====', os.path.basename(f), '=====')
    with open(f,'rb') as fh:
        data = fh.read(0x100000)  # header region enough
    magic = data[:16]
    off, cnt = struct.unpack_from('<II', data, MAPPINGS)
    print('mappings off=0x%x count=%d' % (off, cnt))
    # mapping: uint64 address,size,fileoff; uint32 maxprot,initprot  = 32 bytes
    for i in range(min(cnt, 12)):
        addr, size, fileoff, maxprot, initprot = struct.unpack_from('<QQQII', data, off + 32*i)
        print('  map[%d] addr=0x%x size=0x%x fileoff=0x%x maxprot=%d' % (i, addr, size, fileoff, maxprot))
    soff, scnt = struct.unpack_from('<II', data, SLIDE)
    print('slide off=0x%x count=%d' % (soff, scnt))
    for i in range(min(scnt, 12)):
        # dyld_cache_mapping_and_slide_info: 6x u64 then version(u32),page_size(u32)...
        vals = struct.unpack_from('<QQQQQQII', data, soff + 56*i)
        addr, size, fileoff, slfileoff, infooff, infosize, flags, res = vals
        print('  slide[%d] addr=0x%x size=0x%x infooff=0x%x infosize=%d flags=0x%x' % (i, addr, size, infooff, infosize, flags))
        if infosize and soff + 56*i and infooff < 0x100000:
            try:
                version, page_size, scount, value_add = struct.unpack_from('<III4xQ', data, infooff)
                print('     -> slide_info version=%d page_size=%d count=%d value_add=0x%x' % (version, page_size, scount, value_add))
            except Exception as e:
                print('     -> cannot read slide info:', e)
    # subcache count
    soff2, scnt2 = struct.unpack_from('<II', data, SUBCACHES)
    print('subcaches off=0x%x count=%d' % (soff2, scnt2))
    ioff, icnt = struct.unpack_from('<II', data, IMAGES)
    print('images off=0x%x count=%d' % (ioff, icnt))
    print()
