p=r"C:/ios26/now-041052.bin"
d=open(p,'rb').read().decode('utf-8','replace').replace('\x00','')
L=d.splitlines()
# 找 activation_installed=1 那行 index
idx=None
for i,l in enumerate(L):
    if 'activation_installed=1' in l: idx=i; break
print("activation_installed 行号:",idx)
# 它之后的所有 sb26 行
print("\n=== 钩子安装后的 sb26 输出 ===")
for i in range(idx, min(idx+400,len(L))):
    if 'sb26' in L[i]: print(f"  [{i}] {L[i].strip()[:200]}")
# 钩子后 200 行的所有内容(找卡点)
print("\n=== 钩子安装后 250 行内所有非空、非噪声 ===")
cnt=0
for i in range(idx+1, min(idx+260,len(L))):
    l=L[i].strip()
    if not l: continue
    # 跳过纯 swap pac 行
    if 'pac: traps' in l or 'lt: c' in l or 'tl: c' in l: continue
    print(f"  [{i}] {l[:200]}")
    cnt+=1
    if cnt>90: break
