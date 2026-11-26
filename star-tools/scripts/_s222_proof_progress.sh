#!/bin/bash
echo "=== npz count ==="
ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l
echo "=== island count ==="
ls /root/dsc26_proof/island-*.npz 2>/dev/null | wc -l
echo "=== newest 8 npz by mtime ==="
ls -lt --time-style=+%H:%M:%S /root/dsc26_proof/*.npz 2>/dev/null | head -8 | awk '{print $6, $7}'
echo "=== oldest 3 npz by mtime ==="
ls -ltr --time-style=+%H:%M:%S /root/dsc26_proof/*.npz 2>/dev/null | head -3 | awk '{print $6, $7}'
echo "=== now ==="
date +%H:%M:%S
echo "=== reproven markers in summary (if any) ==="
if test -f /root/dsc26_proof/summary.json; then echo SUMMARY_READY; else echo NO_SUMMARY; fi
echo "=== worker cpu (top 5 by time) ==="
ps -eo time,pcpu,args | grep 'prove-zeta-dyld-cache' | grep -v grep | sort -rn | head -5 | awk '{print $1, $2"%"}'
