#!/bin/bash
set -u
R=/root/star26/s47/work/root
echo "== xpc dir in image =="
ls -la "$R/xpc/" 2>/dev/null | head -10
echo
echo "== launchd.plist present? =="
for p in "$R/xpc/launchd.plist" "$R/System/Library/xpc/launchd.plist"; do
  [ -f "$p" ] && echo "  $(stat -c%s "$p") bytes  $p"
done
echo
echo "== how many jobs in the cache =="
python3 - <<'PY'
import plistlib, os
for p in ["/root/star26/s47/work/root/xpc/launchd.plist",
          "/root/star26/s47/work/root/System/Library/xpc/launchd.plist"]:
    if not os.path.exists(p):
        continue
    d = plistlib.load(open(p, "rb"))
    labels = sorted(d.keys()) if isinstance(d, dict) else []
    print(p, "->", len(labels), "entries")
    for k in labels[:60]:
        print("   ", k)
PY
echo
echo "== LaunchDaemons we ship =="
ls /root/star26/s47/work/root/LaunchDaemons/ 2>/dev/null
