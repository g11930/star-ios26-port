#!/usr/bin/env python3
import struct, os, subprocess
F='/root/dsc26_fix/7zout/dyld_shared_cache_arm64e.35.dyldlinkedit:com.apple.ResourceFork'
r=open(F,'rb').read()
offs=[];pos=0
while pos+4<=len(r):
    v=struct.unpack_from('<I',r,pos)[0]
    if v>len(r) or v<pos: break
    offs.append(v);pos+=4
print('offsets',len(offs),'table',pos)
for i in [0,1,2,100]:
    piece=r[offs[i]:offs[i+1]]
    open('/root/zbm_tool/_piece.zbm','wb').write(piece)
    res=subprocess.run(['/root/zbm_tool/zbm_tool','/root/zbm_tool/_piece.zbm','/root/zbm_tool/_piece.out'],capture_output=True)
    print('piece %d in=%d rc=%d err=%s'%(i,len(piece),res.returncode,res.stderr.decode().strip()))
    if os.path.exists('/root/zbm_tool/_piece.out'):
        d=open('/root/zbm_tool/_piece.out','rb').read()
        print('  out=%d head=%s tail=%s'%(len(d),d[:16].hex(),d[-16:].hex()))
