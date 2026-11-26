#!/bin/bash
L=/mnt/c/ios26/s63-staged.bin
echo "=== logd crash count ==="
strings "$L" | grep -c 'logd xstat 5'
echo "=== syslog/logd dependency errors ==="
strings "$L" | grep -iE 'syslog|logd|os_log|log.*service' | grep -iE 'fail|error|cannot|wait|timed|refus|crash|abort' | head -20
echo "=== XPC checkin / bootstrap errors ==="
strings "$L" | grep -iE 'bootstrap|checkin|check-in|xpc.*fail|service.*not.*found|lookup.*fail|155|1105|1100' | head -25
echo "=== launchd service spawn attempts around first logd crash ==="
strings "$L" | tr '\n' ' ' | sed 's/P28EXIT/\nP28EXIT/g' | grep -B3 -A3 'logd xstat 5' | head -20
echo "=== all P28EXIT xstat non-zero ==="
strings "$L" | grep -oE 'P28EXIT: pid [0-9]+ [^ ]+ xstat [0-9]+' | grep -v 'xstat 0' | sort | uniq -c | head -20
