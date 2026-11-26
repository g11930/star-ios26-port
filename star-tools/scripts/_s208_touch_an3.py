import re,glob
ts_re=re.compile(r'(2025-12-10 [\d:]{8})')

def load(p):
    d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
    return [l.strip() for l in d.split('\n') if l.strip()]

for p in ['/mnt/c/ios26/s208-live6.bin','/mnt/c/ios26/s208-touch1.bin']:
    L=load(p)
    print(f"\n######## {p}  ({len(L)} lines) ########")
    def cnt(s): return sum(1 for l in L if s in l)
    print("  swap #:",cnt('swap #'),"| frames in:",cnt('frames in'),"| MiniIOMobileFramebuffer:",cnt('MiniIOMobileFramebuffer'))
    print("  tl: s:",cnt('tl: s'),"| tl: fw:",cnt('tl: fw'),"| tl: cnt:",cnt('tl: cnt'))
    print("  'draw ... has run':",cnt('has run for'),"| 'commit ... has not moved':",cnt('has not moved'))
    # swap 行的最后时间戳
    for key in ['swap #','frames in','tl: fw','has not moved','has run for']:
        hits=[l for l in L if key in l]
        if hits:
            t=ts_re.search(hits[-1])
            print(f"  last '{key}' at {t.group(1) if t else '?'} : {hits[-1][:120]}")
    # tl: cnt 计数非零的行
    nz=[l for l in L if 'tl: cnt' in l and not re.search(r'tl: cnt 0 0 0 0 0',l)]
    print("  tl: cnt nonzero rows:",len(nz))
    for l in nz[-8:]: print("   ",l[:140])
    # 时间戳范围
    allt=[ts_re.search(l) for l in L]
    allt=[m.group(1) for m in allt if m]
    if allt: print("  ts range:",allt[0],"->",allt[-1])
