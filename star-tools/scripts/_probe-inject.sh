#!/bin/bash
set -u
ROOT=/root/star26/s41/work/root
echo "== who references libannibalemetal =="
grep -rl "libannibalemetal" $ROOT 2>/dev/null | head -20
echo
echo "== who references libannibale.dylib =="
grep -rl "libannibale\.dylib" $ROOT 2>/dev/null | head -20
echo
echo "== LaunchDaemons with annibale =="
grep -rl "annibale" $ROOT/System/Library/LaunchDaemons 2>/dev/null | head -20
echo
echo "== backboardd plist =="
ls -l $ROOT/System/Library/LaunchDaemons/com.apple.backboardd.plist 2>/dev/null
python3 - <<'PY'
import plistlib
p="/root/star26/s41/work/root/System/Library/LaunchDaemons/com.apple.backboardd.plist"
try:
    d=plistlib.load(open(p,'rb'))
    print(plistlib.dumps(d).decode()[:3000])
except Exception as e:
    print("ERR", e)
PY
