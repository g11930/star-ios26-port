#!/bin/bash
set -u
P=/root/ref/dada/kernel/xnu-12377.121.6-dada.patch
T=/root/star26/star-native

echo "=== dada patch: bsd/kern + libkern/cs related files ==="
grep -n '^diff --git' $P | grep -E 'kern_exec|kern_cs|kern_priv|cs_blob|ubc|csops|EXTERNAL|mac_' | head -20

echo "=== our kern_exec.c csflags section (8990-9060) ==="
sed -n '8990,9060p' $T/bsd/kern/kern_exec.c

echo "=== our kern_exec.c 9150-9250 (CS_SIGNED|CS_VALID) ==="
sed -n '9150,9250p' $T/bsd/kern/kern_exec.c
