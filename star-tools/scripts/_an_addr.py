import re
p='C:/ios26/now-032817.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
L=d.splitlines()

# 24 单页地址
addrs=[]
for i,l in enumerate(L):
    m=re.search(r'pac: page (0x[0-9a-f]+) n=(\d+)',l)
    if m: addrs.append((i,int(m.group(1),16),int(m.group(2))))
print("=== 24 单页地址分布 ===")
buckets={}
for i,a,n in addrs:
    hi=a>>32
    buckets[hi]=buckets.get(hi,0)+1
for hi,cnt in sorted(buckets.items()):
    print(f"  0x{hi:x}xxxx xxxx : {cnt} 页")

# 紧邻单页改写的上下文（看是什么进程触发的）
print()
print("=== 首次单页改写前后上下文 (行 3185..3210) ===")
for i in range(3185,3211):
    if i<len(L): print(f"  [{i}] {L[i].strip()[:180]}")

# 统计行 pages 增长与 instrs 的比值 —— 判断是否有未记录页
print()
print("=== 统计行采样 (pages/instrs 增长) ===")
for i in range(3190,len(L),max(1,(len(L)-3190)//12)):
    s=L[i].strip()
    if s.startswith('pac: traps='): print(f"  [{i}] {s[:150]}")

# 找 syscall / exec / code signing 相关
print()
print("=== AMFI / cdhash / code signing / exec 相关 ===")
for kw in ['AMFI','amfi','cdhash','Code Signing','code signature','invalid signature',
           'platform binary','platform_binary','CS_','cs_validate','proc_exec',
           'execve','vnode','TEXT segment','__TEXT','dyld:','DYLD']:
    hits=[(i,l.strip()) for i,l in enumerate(L) if kw in l]
    if hits:
        print(f"--- {kw} ({len(hits)}) ---")
        for i,l in hits[:5]: print(f"  [{i}] {l[:175]}")
