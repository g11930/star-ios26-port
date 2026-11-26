#!/bin/bash
set -u
R=/root/star26/s34/work/root
echo "=== rc.jobs ==="
cat $R/etc/rc.jobs 2>/dev/null | head -40
echo "=== etc listing ==="
ls $R/etc | head -20
echo "=== launches ==="
ls $R/LaunchDaemons | wc -l
echo "=== launchctl on iOS root ==="
ls -la /root/sys-root/bin/launchctl /root/sys-root/usr/bin/launchctl 2>/dev/null
echo "=== our jobs ==="
for p in com.annibale.demo com.annibale.input26; do echo "--- $p"; python3 -c "
import plistlib,sys
d=plistlib.load(open('$R/LaunchDaemons/$p.plist','rb'))
for k in ('Label','ProgramArguments','EnvironmentVariables','RunAtLoad','KeepAlive','UserName','StandardErrorPath'):
    print(' ',k,'=',d.get(k))
"; done
