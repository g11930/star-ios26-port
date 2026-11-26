#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## panic block: full text ##########"
strings -a "$F" | sed -n '/--- panic buffer ---/,$p' | head -60
echo
echo "########## panic count ##########"
echo -n "panic(cpu = "; strings -a "$F" | grep -c "^panic(cpu"
echo -n "Paniclog version = "; strings -a "$F" | grep -c "Paniclog version"
echo
echo "########## corpse ##########"
strings -a "$F" | grep -i "corpse" | head -20
echo
echo "########## ufs run summary (last) ##########"
strings -a "$F" | grep -A12 "what happened in this run" | tail -20
echo
echo "########## IOSurface creations ##########"
strings -a "$F" | grep "created surface" | head -20
echo
echo "########## SpringBoard pid validity ##########"
strings -a "$F" | grep -iE "SpringBoard:[0-9]+; valid|not a system shell|backboard.client" | head -15
