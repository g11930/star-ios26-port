#!/usr/bin/env python3
"""只读：评估 3 个空 dyldlinkedit 分片对证明器的实际影响面。
统计有多少 image 的 instruction sections / LINKEDIT / function starts 落在空分片地址范围。"""
import sys, struct
sys.path.insert(0, '/root/dsc26_zeta_scripts')
import zeta_dyld_cache as dc

# 容忍空分片
orig = dc.CacheFile.__init__
def patched(self, path):
    from pathlib import Path
    import mmap
    self.path = Path(path)
    self.handle = self.path.open('rb')
    self.data = b'' if self.path.stat().st_size == 0 else mmap.mmap(self.handle.fileno(), 0, access=mmap.ACCESS_READ)
    if len(self.data) >= 16 and not (self.data[:16].startswith(b'dyld_v1') and self.data[:16].rstrip(b'\0').endswith(b'arm64e')):
        raise ValueError('not arm64e')
    off,cnt = struct.unpack_from('<II', self.data, dc.HEADER_MAPPINGS) if len(self.data)>=dc.HEADER_MAPPINGS+8 else (0,0)
    self.mappings=[struct.unpack_from('<QQQII',self.data,off+32*i) for i in range(cnt)]
    self.signature=struct.unpack_from('<QQ',self.data,dc.HEADER_SIGNATURE) if len(self.data)>=dc.HEADER_SIGNATURE+16 else (0,0)
    so,sc=struct.unpack_from('<II',self.data,dc.HEADER_MAPPING_SLIDE) if len(self.data)>=dc.HEADER_MAPPING_SLIDE+8 else (0,0)
    self.slid=[struct.unpack_from('<QQQQQQII',self.data,so+56*i) for i in range(sc)]
dc.CacheFile.__init__=patched

MAIN='/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e'
cache=dc.Cache(MAIN)
# 空分片索引
empty_idx=set()
for i,cf in enumerate(cache.files):
    if len(cf.data)==0:
        empty_idx.add(i)
print('empty file indexes:', empty_idx, flush=True)
# 这些文件负责的地址范围
empty_ranges=[]
for i in empty_idx:
    for addr,size,fileoff,mp,_ in cache.files[i].mappings if hasattr(cache.files[i],'mappings') else []:
        empty_ranges.append((addr,addr+size,i))
# 注意：空分片没有 header 也读不到 mappings，用主文件 subcache 表的 vmoff + 从 regions 推断
# regions 里含 file index，直接筛
empty_addr_ranges=[(s,s+sz,fi) for s,sz,fi,_,_ in cache.regions if fi in empty_idx]
print('empty address ranges:', [(hex(a),hex(b),fi) for a,b,fi in empty_addr_ranges], flush=True)

def in_empty(addr):
    for a,b,_ in empty_addr_ranges:
        if a<=addr<b: return True
    return False

# 遍历所有 image，看关键的 section/命令地址是否落在空区
n=0; text_in_empty=0; linkedit_in_empty=0; unwind_in_empty=0; fs_in_empty=0
affected=[]
for addr,path in cache.images:
    n+=1
    try:
        im=dc.Image(cache,addr,path)
    except Exception:
        continue
    txt=[s for s in im.sections if s['flags']&dc.INSTRUCTIONS and s['size']]
    if any(in_empty(s['addr']) for s in txt):
        text_in_empty+=1; affected.append(path)
    if '__LINKEDIT' in im.segments and in_empty(im.segments['__LINKEDIT']['vmaddr']):
        linkedit_in_empty+=1
    if any(s['name']=='__unwind_info' and in_empty(s['addr']) for s in im.sections):
        unwind_in_empty+=1
    if im.function_starts_command and im.function_starts_command[1]:
        if '__LINKEDIT' in im.segments:
            fs_off=im.function_starts_command[0]
            fs_va=im.segments['__LINKEDIT']['vmaddr']+fs_off-im.segments['__LINKEDIT']['fileoff']
            if in_empty(fs_va): fs_in_empty+=1

print('total images:', n, flush=True)
print('images with __text in empty range:', text_in_empty, flush=True)
print('images with __LINKEDIT in empty range:', linkedit_in_empty, flush=True)
print('images with __unwind_info in empty range:', unwind_in_empty, flush=True)
print('images with function_starts in empty range:', fs_in_empty, flush=True)
print('sample affected text images:', affected[:10], flush=True)
