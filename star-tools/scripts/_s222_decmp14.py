#!/usr/bin/env python3
"""用 ctype-12 的 lzfse-per-piece 逻辑解压 ctype-14 的 decmpfs resource fork。
7z 已提取出 ResourceFork 和 decmpfs 头。"""
import sys, os, struct, time
sys.path.insert(0, '/root/star26/hackios-xnu-userland/tools/apfs')
import apfs_reader as ar
import lzfse

BASE='/root/dsc26_fix/7zout'
names=[
 'dyld_shared_cache_arm64e.35.dyldlinkedit',
 'dyld_shared_cache_arm64e.72.dyldlinkedit',
 'dyld_shared_cache_arm64e.83.dyldlinkedit',
]
OUT='/root/dsc26_fix'
BS=ar.DECMPFS_BLOCK_SIZE

for name in names:
    rpath=os.path.join(BASE, name+':com.apple.ResourceFork')
    hpath=os.path.join(BASE, name+':com.apple.decmpfs')
    print('===',name,'===',flush=True)
    if not os.path.exists(rpath) or not os.path.exists(hpath):
        # 尝试从 7zout 提取这个文件的 xattr
        print('  xattrs not extracted yet, skip',flush=True); continue
    hdr=open(hpath,'rb').read()
    magic,ctype,usize=struct.unpack_from('<IIQ',hdr,0)
    print('  magic=%s ctype=%d usize=%d'%(hdr[:4],ctype,usize),flush=True)
    rsrc=open(rpath,'rb').read()
    print('  rfork len=%d'%len(rsrc),flush=True)
    t0=time.time()
    try:
        data_off,map_off,data_len,map_len=struct.unpack_from('>IIII',rsrc,0)
        base=data_off+4
        nblocks=struct.unpack_from('<I',rsrc,base)[0]
        want=(usize+BS-1)//BS
        print('  data_off=%d nblocks=%d want=%d'%(data_off,nblocks,want),flush=True)
        if nblocks!=want:
            print('  WARNING nblocks mismatch',flush=True)
        out=bytearray()
        bad=0
        for i in range(min(nblocks,want)):
            off,length=struct.unpack_from('<II',rsrc,base+4+8*i)
            piece=rsrc[base+off:base+off+length]
            n=min(BS,usize-len(out))
            try:
                if piece[:1]==b'\xff':
                    chunk=piece[1:1+n]
                else:
                    chunk=lzfse.decompress(piece)[:n]
                out+=chunk
            except Exception as e:
                bad+=1
                if bad<=3: print('    piece %d ERR %s'%(i,str(e)[:60]),flush=True)
                out+=b'\x00'*n
        print('  decompressed %d (want %d) bad=%d in %.1fs'%(len(out),usize,bad,time.time()-t0),flush=True)
        with open(os.path.join(OUT,name),'wb') as f:
            f.write(out)
        print('  wrote',os.path.join(OUT,name),flush=True)
    except Exception as e:
        print('  ERROR',type(e).__name__,str(e)[:200],flush=True)
