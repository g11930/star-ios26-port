import re
p="/root/star26/star-native/osfmk/kern/zalloc.h"
lines=open(p).read().splitlines()
# find the enum block containing ZONE_ID__ZERO
start=None
for i,l in enumerate(lines):
    if 'ZONE_ID__ZERO' in l and '=' not in l:
        start=i; break
print("ZONE_ID__ZERO at line", start+1)
n=0
names=[]
for l in lines[start:]:
    s=l.strip()
    if s.startswith('};'): break
    if s.startswith('ZONE_ID_') and not s.startswith('ZONE_ID__'):
        nm=s.split()[0].rstrip(',')
        names.append((n,nm))
        n+=1
    elif s.startswith('ZONE_ID__'):
        # aliases with explicit =, don't advance counter
        pass
# careful: aliases like ZONE_ID__FIRST_RO = ... do not advance
# recompute properly: only bare enumerators advance
n=0
names=[]
for l in lines[start:]:
    s=l.strip()
    if s.startswith('};'): break
    m=re.match(r'(ZONE_ID_[A-Z0-9_]+)\s*(,|=)', s)
    if not m: continue
    nm=m.group(1)
    if '=' in s[m.end(1):m.end(1)+2]:
        # explicit value alias; skip
        continue
    names.append((n,nm)); n+=1
for idx,nm in names:
    if idx in (27,28,65534) or 'IPC_PORT' in nm or 'WAITQ' in nm or 'TURNSTILE' in nm or 'SEMAPHORE' in nm:
        print(f"  {idx}: {nm}")
