#!/bin/bash
P=/mnt/c/ios26/s94-live3.bin
echo "=== A) runningboard connection outcome ==="
python3 - "$P" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
ls=t.split('\n')
for i,l in enumerate(ls):
    if 'FBSystemShellInitialize' in l or 'com.apple.runningboard' in l or 'runningboard' in l.lower():
        print("  ",l[:220])
PY
echo "=== B) runningboardd process activity (is it alive/answering?) ==="
python3 - "$P" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
ls=[l for l in t.split('\n') if 'runningboardd[' in l]
print("count",len(ls))
for l in ls[-20:]: print("  ",l[:200])
PY
echo "=== C) sbmetal registration device (the 0 vs 1 question) ==="
python3 - "$P" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
for l in t.split('\n'):
    if 'sbmetal26' in l or 'registration completed' in l or 'default_before' in l or 'adopted native' in l:
        print("  ",l[:200])
PY
echo "=== D) compare with s90 mature log: same markers ==="
S90=/mnt/c/ios26/s90-live.bin
python3 - "$S90" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
for l in t.split('\n'):
    if 'FBSystemShellInitialize' in l or 'sbmetal26: registration completed' in l or 'default_before' in l:
        print("  ",l[:200])
PY
