#!/bin/bash
set -u
ROOT=/root/star26/s41/work/root
echo "== LaunchDaemons =="
ls -1 $ROOT/LaunchDaemons | head -40
echo
echo "== backboardd plist =="
ls -l $ROOT/LaunchDaemons/com.apple.backboardd.plist 2>/dev/null
python3 - <<'PY'
import plistlib, glob
for p in glob.glob("/root/star26/s41/work/root/LaunchDaemons/*.plist"):
    try:
        d = plistlib.load(open(p,'rb'))
    except Exception as e:
        print("ERR", p, e); continue
    s = plistlib.dumps(d).decode('utf-8','replace')
    if 'annibale' in s.lower() or 'backboard' in p or 'SpringBoard' in s:
        print("----", p)
        print(s[:2500])
PY
