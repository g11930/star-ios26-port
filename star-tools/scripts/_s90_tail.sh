#!/bin/bash
OUT=/mnt/c/ios26/s90_tail.out
: > "$OUT"
P=/mnt/c/ios26/s90-live.bin
e(){ echo "$@" >> "$OUT"; }

e "=== 1) last 60 lines of live log ==="
python3 - "$P" <<'PY' >> "$OUT"
import sys
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
lines=[l for l in t.split('\n') if l.strip()]
for l in lines[-60:]:
    print(l)
PY

e ""
e "=== 2) SpringBoard / launchd / backboardd last appearance ==="
python3 - "$P" <<'PY' >> "$OUT"
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
lines=t.split('\n')
for key in ["SpringBoard[","launchd[","backboardd[33","SpringBoard[33","P28EXIT"]:
    hits=[(i,l) for i,l in enumerate(lines) if key in l]
    print(f"--- {key}: {len(hits)} hits, last 3 ---")
    for i,l in hits[-3:]:
        print("   ",l[:200])
PY

e ""
e "=== 3) P28EXIT list (which pids died) ==="
python3 - "$P" <<'PY' >> "$OUT"
import sys,re,collections
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
c=collections.Counter()
for m in re.finditer(r'P28EXIT: pid (\d+) (\S+) xstat (\d+)', t):
    c[(m.group(1),m.group(2),m.group(3))]+=1
for k,v in c.most_common(20):
    print("   ",k,"x",v)
PY

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
