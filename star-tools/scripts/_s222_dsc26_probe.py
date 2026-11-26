#!/usr/bin/env python3
"""只读：核查 /root/dsc26 完整 arm64e cache 的 header，验证是否满足 zeta 工具假设。
按 zeta_dyld_cache.py 的 HEADER_* 常量解析。"""
import struct, os, glob

D = '/root/dsc26/System/Library/Caches/com.apple.dyld'
MAIN = D + '/dyld_shared_cache_arm64e'
MAPPINGS, SIGNATURE, SLIDE, SUBCACHES, IMAGES = 0x10, 0x28, 0x138, 0x188, 0x1c0
SUBCACHE_ENTRY = 56

print('=== 主文件 ===')
print('size:', os.path.getsize(MAIN))
with open(MAIN, 'rb') as fh:
    head = fh.read(0x60000)
print('magic:', head[:16])

off, cnt = struct.unpack_from('<II', head, MAPPINGS)
print('mappings: off=0x%x count=%d' % (off, cnt))
for i in range(min(cnt, 8)):
    addr, size, fileoff, maxprot, initprot = struct.unpack_from('<QQQII', head, off + 32*i)
    print('  map[%d] addr=0x%x size=0x%x fileoff=0x%x maxprot=%d' % (i, addr, size, fileoff, maxprot))

sig_off, sig_size = struct.unpack_from('<QQ', head, SIGNATURE)
print('signature: off=0x%x size=%d' % (sig_off, sig_size))

soff, scnt = struct.unpack_from('<II', head, SLIDE)
print('mapping_slide: off=0x%x count=%d' % (soff, scnt))
for i in range(min(scnt, 8)):
    addr, size, fileoff, slfileoff, infooff, infosize, flags, res = struct.unpack_from('<QQQQQQII', head, soff + 56*i)
    print('  slide[%d] addr=0x%x size=0x%x infooff=0x%x infosize=%d flags=0x%x' % (i, addr, size, infooff, infosize, flags))

suboff, subcnt = struct.unpack_from('<II', head, SUBCACHES)
print('subcaches: off=0x%x count=%d' % (suboff, subcnt))
suffixes = []
for i in range(min(subcnt, 100)):
    e = suboff + SUBCACHE_ENTRY*i
    suffix = head[e+24:e+56].split(b'\0',1)[0].decode(errors='replace')
    suffixes.append(suffix)
if suffixes:
    print('  first suffixes:', suffixes[:6])
    print('  last suffixes:', suffixes[-4:])

ioff, icnt = struct.unpack_from('<II', head, IMAGES)
print('images: off=0x%x count=%d' % (ioff, icnt))

# 分片存在性核对
missing = [s for s in suffixes if not os.path.exists(MAIN + s)]
print('missing subcaches: %d' % len(missing), missing[:5] if missing else '')

# slide info version: 去每个分片查
print()
print('=== slide info version (逐文件 header 的 slide 段) ===')
allfiles = [MAIN] + [MAIN + s for s in suffixes if os.path.exists(MAIN+s)]
versions = set()
for f in allfiles[:6]:
    try:
        with open(f,'rb') as fh:
            h = fh.read(0x100000)
        so, sc = struct.unpack_from('<II', h, SLIDE)
        for i in range(min(sc,4)):
            addr, size, fileoff, slfileoff, infooff, infosize, flags, res = struct.unpack_from('<QQQQQQII', h, so + 56*i)
            if infosize and infooff < 0x100000:
                ver, psize, count = struct.unpack_from('<III', h, infooff)
                versions.add(ver)
                print('  %s: slide ver=%d page=%d count=%d' % (os.path.basename(f), ver, psize, count))
                break
    except Exception as e:
        print('  %s: ERR %s' % (os.path.basename(f), e))
print('distinct slide versions:', sorted(versions))
