#!/bin/bash
# s60 timeline: resident phase after boot complete
grep -n 'Early boot complete' /tmp/s60.txt | head -1
N=$(grep -n 'Early boot complete' /tmp/s60.txt | head -1 | cut -d: -f1)
if [ -z "$N" ]; then N=1800; fi
awk -v n="$N" 'NR>=n' /tmp/s60.txt | grep -E 'EXECDBG: loading' | grep -vE 'xpcproxy|/usr/libexec/logd' | sed 's/ cputype.*//' | head -40
echo === spawn failures ===
awk -v n="$N" 'NR>=n' /tmp/s60.txt | grep 'com.apple.xpc.launchd' | grep -iE 'Error>|Warning>|failed|Unable|could not' | head -15
