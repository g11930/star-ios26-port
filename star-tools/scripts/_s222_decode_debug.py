#!/usr/bin/env python3
import struct, lzfse
F='/root/dsc26_fix/7zout/dyld_shared_cache_arm64e.35.dyldlinkedit:com.apple.ResourceFork'
rsrc=open(F,'rb').read()
# offsets 表
offsets=[]; pos=0
while pos+4<=len(rsrc):
    v=struct.unpack_from('<I',rsrc,pos)[0]
    if v>len(rsrc) or v<pos: break
    offsets.append(v); pos+=4
print('offsets:',len(offsets),'table bytes:',pos,'first off:',hex(offsets[0]))
for i in [0,1,2,10,100]:
    start=offsets[i]; end=offsets[i+1]
    piece=rsrc[start:end]
    print('piece %d: off=%x..%x len=%d head=%s'%(i,start,end,len(piece),piece[:12].hex()))
    try:
        if piece[:1]==b'\xff':
            c=piece[1:]
            print('   raw(ff) len',len(c))
        else:
            c=lzfse.decompress(piece)
            print('   lzfse ->',len(c))
    except Exception as e:
        print('   ERR',repr(e))
