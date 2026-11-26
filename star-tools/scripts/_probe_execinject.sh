#!/bin/bash
set -u
echo "== exec_inject in kernel tree =="
grep -rn "exec_inject" /root/star26/star-native/ 2>/dev/null | head -20
echo
echo "== inject-related sysctl names in kernel =="
grep -rn "inject" /root/star26/star-native/bsd/kern/*.c 2>/dev/null | head -20
echo
echo "== search whole star-native for SYSCTL name exec_inject =="
grep -rn "\"exec_inject\"" /root/star26/star-native/ 2>/dev/null | head -10
