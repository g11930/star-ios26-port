#!/usr/bin/env python3
"""ctype-14 decmpfs: 开头是 LE u32 piece offset 数组，每 piece lzfse 压缩。
推断 piece 数与块大小，解压并校验。"""
import struct, os, time, lzfse

# Apple decmpfs ctype 14 = COMPRESSION_LZFSE with 64KB uncompressed blocks?
# 观察 offset 差值 ~0x3139 (12601) -> 压缩后每块 ~12KB，对应解压 64KB
BASE='/root/dsc26_fix/7zout'
OUT='/root/dsc26_fix'
names=[
 'dyld_shared_cache_arm64e.35.dyldlinkedit',
 'dyld_shared_cache_arm64e.72.dyldlinkedit',
 'dyld_shared_cache_arm64e.83.dyldlinkedit',
]
CHUNKS=(65536,32768,16384)  # 候选解压块大小

def try_decode(rsrc, usize, chunk):
    # offset 表: 从 0 开始的 LE u32 数组, 直到某个值指向 rsrc 末尾附近
    # 找表长: 连续递增的 offset, 最后一个 offset < len(rsrc)
    offsets=[]
    pos=0
    while pos+4<=len(rsrc):
        v=struct.unpack_from('<I',rsrc,pos)[0]
        if v>len(rsrc) or v<pos:
            break
        offsets.append(v)
        pos+=4
        if len(offsets)>100000:
            break
    if not offsets:
        return None
    nblocks=(usize+chunk-1)//chunk
    print('    chunk=%d: offsets found=%d, need nblocks=%d, first=%x last=%x rsrc=%x'%(
        chunk,len(offsets),nblocks,offsets[0],offsets[-1],len(rsrc)),flush=True)
    if len(offsets) not in (nblocks, nblocks+1):
        return None
    out=bytearray()
    bad=0
    for i in range(nblocks):
        start=offsets[i]
        end=offsets[i+1] if i+1<len(offsets) else len(rsrc)
        piece=rsrc[start:end]
        n=min(chunk,usize-len(out))
        try:
            if piece[:1]==b'\xff':
                c=piece[1:1+n]
            else:
                c=lzfse.decompress(piece)
            out+=c[:n]
            if len(c)<n:
                out+=b'\x00'*(n-len(c))
        except Exception as e:
            bad+=1
            out+=b'\x00'*n
            if bad<=2: print('      piece %d err %s'%(i,str(e)[:50]),flush=True)
    return bytes(out),bad

for name in names:
    print('===',name,'===',flush=True)
    hdr=open(os.path.join(BASE,name+':com.apple.decmpfs'),'rb').read()
    magic,ctype,usize=struct.unpack_from('<IIQ',hdr,0)
    rsrc=open(os.path.join(BASE,name+':com.apple.ResourceFork'),'rb').read()
    print('  ctype=%d usize=%d rfork=%d'%(ctype,usize,len(rsrc)),flush=True)
    t0=time.time()
    best=None
    for chunk in CHUNKS:
        r=try_decode(rsrc,usize,chunk)
        if r and r[1]==0:
            best=(chunk,r[0]); break
    if best:
        chunk,data=best
        print('  SUCCESS chunk=%d len=%d in %.1fs'%(chunk,len(data),time.time()-t0),flush=True)
        with open(os.path.join(OUT,name),'wb') as f:
            f.write(data)
        print('  wrote',flush=True)
    else:
        print('  no clean decode',flush=True)
