#!/bin/bash
echo === SpringBoard pid32 traces ===
grep 'say 32 trace' /tmp/s60.txt | tail -10
echo === autounlock ===
grep -iE 'autounlock|unlock' /tmp/s60.txt | grep -v cmdline | head -8
echo === last 40 non-plist lines ===
grep -vE 'LaunchDaemons|\.plist|STARX|EAI_|LM_|ME_|AES_|parse_machfile' /tmp/s60.txt | awk 'NR>=1' | tail -40 | head -25
