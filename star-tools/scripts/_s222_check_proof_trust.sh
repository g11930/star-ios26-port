#!/bin/bash
echo "=== proof processes ==="
ps -eo pid,etime,pcpu,pmem,stat,comm,args 2>/dev/null | grep -E 'prove-zeta|zeta-venv' | grep -v grep | head -30
echo "=== proof dir detail ==="
ls -la /root/dsc26_proof/ 2>/dev/null | head -20
du -sh /root/dsc26_proof/ 2>/dev/null
echo "=== trust in systemos.dmg ==="
7z l /root/star26/ipsw/systemos.dmg 2>/dev/null | grep -iE 'trust' | head -40
echo "=== trust in appos.dmg ==="
7z l /root/star26/ipsw/appos.dmg 2>/dev/null | grep -iE 'trust' | head -40
