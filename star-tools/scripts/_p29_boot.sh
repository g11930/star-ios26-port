#!/bin/bash
echo === P29 boot tasks ===
grep -E 'Doing boot task' /tmp/p29.txt | head -20
echo === P29 pid9 ===
grep 'P28EXIT: pid 9' /tmp/p29.txt | head -3
echo === P29 launchd pid ===
grep -E 'Successfully spawned (com\.apple\.)?launchd|pid 9' /tmp/p29.txt | head -5
echo === P29 SpringBoard ===
grep -E 'SpringBoard' /tmp/p29.txt | grep -iE 'spawn|Notice' | head -5
echo === s60 604s timeline: who after launchd exit ===
grep -nE 'restore-datapartition|pid 9 launchd|mount-phase-2' /tmp/s60.txt | head -5
