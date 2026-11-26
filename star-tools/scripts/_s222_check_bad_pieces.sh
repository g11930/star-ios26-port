#!/bin/bash
BASE=/root/dsc26_fix/7zout
TOOL=/root/zbm_tool/zbm_tool
for name in dyld_shared_cache_arm64e.35.dyldlinkedit dyld_shared_cache_arm64e.72.dyldlinkedit dyld_shared_cache_arm64e.83.dyldlinkedit; do
  echo "=== $name ==="
  python3 - "$BASE" "$name" <<'PYEOF'
import struct,sys,os
base,name=sys.argv[1],sys.argv[2]
rsrc=open(os.path.join(base,name+':com.apple.ResourceFork'),'rb').read()
hdr=open(os.path.join(base,name+':com.apple.decmpfs'),'rb').read()
magic,ctype,usize=struct.unpack_from('<IIQ',hdr,0)
CHUNK=65536; nblocks=(usize+CHUNK-1)//CHUNK
offsets=[];pos=0
while pos+4<=len(rsrc):
    v=struct.unpack_from('<I',rsrc,pos)[0]
    if v>len(rsrc) or v<pos: break
    offsets.append(v);pos+=4
print(' nblocks',nblocks,'offsets',len(offsets),'rsrc_len',len(rsrc),'usize',usize)
# show last 10 piece lengths + content head
for i in range(max(0,len(offsets)-11),len(offsets)-1):
    start=offsets[i];end=offsets[i+1]
    piece=rsrc[start:end]
    print(f' piece {i}: off={start:#x}..{end:#x} len={len(piece)} head={piece[:8].hex()}')
PYEOF
done
