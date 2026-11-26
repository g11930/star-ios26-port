#!/bin/bash
P=/mnt/c/ios26/s94-live3.bin
echo "=== 1) SpringBoard all lines (where it stops) ==="
python3 - "$P" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
ls=[l for l in t.split('\n') if 'SpringBoard[' in l]
print("count",len(ls))
for l in ls[-25:]: print("  ",l[:200])
PY
echo "=== 2) repeated-pattern detection (normalized message -> count) ==="
python3 - "$P" <<'PY'
import sys,re,collections
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
ls=[l for l in t.split('\n') if l.strip()]
norm=collections.Counter()
for l in ls:
    # strip timestamp, pid[thread], hex addrs, numbers -> normalized message
    s=re.sub(r'^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+[+]\d{4} ','',l)
    s=re.sub(r'\[\d+:\d+\]','[PID]',s)
    s=re.sub(r'0x[0-9a-fA-F]+','0xX',s)
    s=re.sub(r'\b\d+\b','N',s)
    s=s[:100]
    norm[s]+=1
for msg,c in norm.most_common(25):
    if c>=5: print("  %4d x %s"%(c,msg[:95]))
PY
echo "=== 3) crash/exception lines (all) ==="
python3 - "$P" <<'PY'
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
for l in t.split('\n'):
    if re.search(r'\b(crash|Crash|CRASH|exception|Exception|abort|Abort|SIG[A-Z]+|Terminating)\b',l):
        print("  ",l[:220])
PY
echo "=== 4) key lifecycle markers ==="
python3 - "$P" <<'PY'
import sys
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
for p in ["didFinishLaunching","application:didFinish","SpringBoard.*launch","_setupActivationState",
          "activation call","boot unlock","first_frame","WindowServer","BootUI","Apple Logo",
          "HideAppleLogo","overlay","swap","commit","registration completed","MTLDevice",
          "autounlock","lock screen","CoverSheet","SBLockScreen"]:
    import re
    print("  %-28s %d"%(p,len(re.findall(p,t))))
PY
