#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## 1. annibalemetal: which run? (timestamps) ##########"
strings -a "$F" | grep "annibalemetal" | head -3
echo "..."
strings -a "$F" | grep "annibalemetal" | tail -3
echo
echo "########## 2. 'no row changed' - the black screen proof ##########"
strings -a "$F" | grep "no row changed" | head -5
echo
echo "########## 3. Metal device creation attempts ##########"
strings -a "$F" | grep -iE "MTLCreateSystemDefaultDevice|AGXAcceleratorG13|AGXDevice|IOGPUDevice|Metal:|metal device|trying to use metal" | head -20
echo
echo "########## 4. backboardd .ips crash list ##########"
strings -a "$F" | grep -oE "backboardd-2025-[0-9-]+\.ips" | sort -u
echo
echo "########## 5. backboardd exit / relaunch ##########"
strings -a "$F" | grep -iE "backboardd.*exited|backboardd.*SIGTRAP|backboardd.*crash|backboardd.*ran for" | head -15
echo
echo "########## 6. SpringBoard exit ##########"
strings -a "$F" | grep -iE "SpringBoard.*exited|SpringBoard.*SIGTRAP|SpringBoard.*ran for" | head -10
