#!/bin/bash
# P29 vs s60: pid 1 structure and launchd pid
echo === P29 init/launchd ===
grep -E 'init: process 1|EXECDBG: loading /sbin/launchd|EXECDBG: loading /annibale/sbin/init|pid 1 |P28EXIT: pid 1 ' /tmp/p29.txt | head -12
echo === P29 launchd exits? ===
grep 'P28EXIT' /tmp/p29.txt | head -8
echo === s60 init line ===
grep -E 'init: process 1' /tmp/s60.txt | head -3
echo === s60 pid1 area ===
grep -E 'P28EXIT: pid (1|9) ' /tmp/s60.txt | head -5
