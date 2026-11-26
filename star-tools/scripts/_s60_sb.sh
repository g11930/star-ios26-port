#!/bin/bash
# s60: lsprobe outputs, heartbeats, SpringBoard/backboardd state
echo === lsprobe ===
grep 'lsprobe' /tmp/s60.txt | tail -6
echo === heartbeats ===
grep -E 'say (9|17) trace' /tmp/s60.txt | tail -6
echo === sb26 / annibale notes ===
grep -E 'sb26|autounlock|annibale:' /tmp/s60.txt | head -10
echo === SpringBoard plist import ===
grep -E 'user/501/com.apple.SpringBoard|SpringBoard.app' /tmp/s60.txt | grep 'launchd' | head -6
