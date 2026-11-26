#!/bin/bash
F=/root/star26/star-native/bsd/kern/kern_exec.c
echo "== 7170-7270 =="
sed -n '7170,7270p' "$F"
