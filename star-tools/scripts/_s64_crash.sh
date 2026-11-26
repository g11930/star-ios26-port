#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## 1. metal=0 -> GPU / device creation ##########"
strings -a "$F" | grep -iE "MTLCreateSystemDefaultDevice|AGXAccelerator|AGXDevice|IOGPU|metal device|no metal|Metal is not|metal=0" | head -25
echo
echo "########## 2. EXC / exception / crash in THIS run ##########"
strings -a "$F" | grep -iE "EXC_BAD|EXC_CRASH|Exception Type|Termination Reason|Kernel data abort|panic|SIGSEGV|SIGBUS|SIGILL" | head -25
echo
echo "########## 3. backboardd[303] last 40 distinct lines ##########"
strings -a "$F" | grep "backboardd\[303" | tail -40
echo
echo "########## 4. BKWorkspace / scene / UI bring-up ##########"
strings -a "$F" | grep -iE "BKWorkspace|workspace|scene|FBApplication|SBApplication|frontmost|booted" | head -25
