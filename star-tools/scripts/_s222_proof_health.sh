#!/bin/bash
echo "=== proof processes (pid etime cpu-time %cpu stat cmd) ==="
ps -eo pid,etime,time,pcpu,stat,args | grep -E 'prove-zeta-dyld-cache|multiprocessing' | grep -v grep | head -30
echo "=== npz count ==="
ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l
echo "=== island count ==="
ls /root/dsc26_proof/island-*.npz 2>/dev/null | wc -l
if test -f /root/dsc26_proof/summary.json; then echo SUMMARY_READY; else echo NO_SUMMARY; fi
