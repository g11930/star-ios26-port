#!/usr/bin/env python3
"""用编译好的 zbm_tool 解压 ctype-14 decmpfs resource fork。
每个 piece 是一个独立 ZBM stream，解压到 64KB，拼成完整文件。"""
import struct, os, subprocess, time, sys

BASE='/root/dsc26_fix/7zout'
OUT='/root/dsc26_fix'
TOOL='/root/zbm_tool/zbm_tool'
CHUNK=65536
names=[
 'dyld_shared_cache_arm64e.35.dyldlinkedit',
 'dyld_shared_cache_arm64e.72.dyldlinkedit',
 'dyld_shared_cache_arm64e.83.dyldlinkedit',
]
only = sys.argv[1] if len(sys.argv)>1 else None

for name in names:
    if only and only not in name: continue
    print('===',name,'===',flush=True)
    hdr=open(os.path.join(BASE,name+':com.apple.decmpfs'),'rb').read()
    magic,ctype,usize=struct.unpack_from('<IIQ',hdr,0)
    rsrc=open(os.path.join(BASE,name+':com.apple.ResourceFork'),'rb').read()
    nblocks=(usize+CHUNK-1)//CHUNK
    # offsets table
    offsets=[]; pos=0
    while pos+4<=len(rsrc):
        v=struct.unpack_from('<I',rsrc,pos)[0]
        if v>len(rsrc) or v<pos: break
        offsets.append(v); pos+=4
    print('  ctype=%d usize=%d blocks=%d offsets=%d table=%dB'%(
        ctype,usize,nblocks,len(offsets),pos),flush=True)
    if len(offsets)!=nblocks+1:
        print('  MISMATCH, skip',flush=True); continue
    t0=time.time()
    out=bytearray(); bad=0; empty=0
    tmpin='/root/zbm_tool/_piece.zbm'; tmpout='/root/zbm_tool/_piece.out'
    for i in range(nblocks):
        start=offsets[i]; end=offsets[i+1]
        piece=rsrc[start:end]
        with open(tmpin,'wb') as f: f.write(piece)
        r=subprocess.run([TOOL,tmpin,tmpout],capture_output=True)
        if r.returncode!=0:
            bad+=1
            if bad<=5: print('    piece %d FAIL: %s'%(i,r.stderr.decode()[:120]),flush=True)
            out+=b'\x00'*min(CHUNK,usize-len(out))
            continue
        with open(tmpout,'rb') as f: d=f.read()
        if not d: empty+=1
        out+=d[:min(CHUNK,usize-len(out))]
        if (i+1)%500==0: print('    %d/%d (%.0fs)'%(i+1,nblocks,time.time()-t0),flush=True)
    print('  done: len=%d want=%d bad=%d empty=%d in %.1fs'%(
        len(out),usize,bad,empty,time.time()-t0),flush=True)
    with open(os.path.join(OUT,name),'wb') as f: f.write(out)
    print('  wrote',os.path.join(OUT,name),flush=True)
