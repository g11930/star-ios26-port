import re, subprocess
P="/root/ref/dada/kernel/xnu-12377.121.6-dada.patch"
targets = [
 "bsd/kern/kern_credential.c",
 "bsd/kern/kern_minimac.c",
 "libkern/amfi/miniamfi.c",
 "libkern/amfi/miniamfi_entitlements.cpp",
 "osfmk/ipc/ipc_policy.c",
 "iokit/Kernel/GenericARMPE.cpp",
 "iokit/IOKit/IOCircularDataQueueImplementation.h",
 "bsd/kern/ubc_subr.c",
 "osfmk/arm64/loader_return.c",
]
with open(P, errors="replace") as f:
    lines=f.readlines()
ranges=[]
cur=None
for i,l in enumerate(lines):
    if l.startswith("diff --git "):
        m=re.search(r" b/(.+?)$",l.rstrip())
        cur=m.group(1) if m else None
        if cur in targets: ranges.append([cur,i,i+1])
    elif cur in targets:
        ranges[-1][2]=i+1
for name,s,e in ranges:
    block="".join(lines[s:e])
    adds=[l for l in block.splitlines() if l.startswith("+") and not l.startswith("+++")]
    print("="*72)
    print(f"### {name}  ({len(adds)} added lines)")
    print("="*72)
    # print first 60 meaningful added lines
    cnt=0
    for l in adds[1:] if adds and adds[0].startswith("+++") else adds:
        if l.strip() in ("+", "+/*", "+ *"): continue
        print(l)
        cnt+=1
        if cnt>=55:
            print("... (truncated)")
            break
