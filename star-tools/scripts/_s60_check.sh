#!/bin/bash
# s60 service spawn counts + heartbeat tail
B=/mnt/c/ios26/s60-staged.bin
strings "$B" > /tmp/s60.txt
for s in cfprefsd configd securityd keybagd launchd_cache_loader MTLCompilerService SpringBoard backboardd logd xpcroleaccountd nanoregistryd; do
	printf '%-22s %s\n' "$s" "$(grep -c "EXECDBG: loading [^ ]*$s" /tmp/s60.txt)"
done
echo === heartbeats ===
grep -E 'say 9 trace|say 17 trace' /tmp/s60.txt | tail -6
echo === launchd errors ===
grep 'com.apple.xpc.launchd' /tmp/s60.txt | grep -iE 'Error>|Unable|cannot load' | head -8
echo === crash/exit ===
grep -E 'P28EXIT' /tmp/s60.txt | grep -v 'xstat 0' | head -10
echo === tail ===
grep -vE 'LaunchDaemons|\.plist|STARX|EAI_|LM_|ME_|AES_' /tmp/s60.txt | tail -20
