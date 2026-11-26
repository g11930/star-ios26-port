#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## run boundaries: boot args dumps ##########"
strings -a "$F" | grep -n "epoch=" | head -20
echo
echo "########## count of run markers ##########"
echo -n "cmdline: (loader dumps) = "; strings -a "$F" | grep -c "^cmdline:"
echo -n "Early boot complete     = "; strings -a "$F" | grep -c "Early boot complete"
echo -n "ufs: native: what happened = "; strings -a "$F" | grep -c "ufs: native: what happened"
echo -n "SpringBoard heartbeat    = "; strings -a "$F" | grep -c "SpringBoard heartbeat started"
echo -n "StartWindowServer        = "; strings -a "$F" | grep -c "StartWindowServer"
echo -n "BKDisplayRenderOverlaySpinny = "; strings -a "$F" | grep -c "BKDisplayRenderOverlaySpinny"
echo -n "annibalemetal            = "; strings -a "$F" | grep -c "annibalemetal"
echo
echo "########## StartWindowServer occurrences w/ context ##########"
strings -a "$F" | grep "StartWindowServer" | head -10
echo
echo "########## SpringBoard heartbeat occurrences ##########"
strings -a "$F" | grep "SpringBoard heartbeat started" | head -10
echo
echo "########## which pids of backboardd appear ##########"
strings -a "$F" | grep -oE "backboardd\[[0-9]+" | sort | uniq -c | sort -rn | head -20
echo
echo "########## spinny overlay occurrences ##########"
strings -a "$F" | grep "BKDisplayRenderOverlaySpinny" | head -10
