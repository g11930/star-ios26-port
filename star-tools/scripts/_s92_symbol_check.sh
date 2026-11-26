#!/bin/bash
# s92: verify minimac symbols in s91 kernel
K=/root/star26/s91/parts/kernel
nm "$K" 2>/dev/null | grep -iE 'miniamfi|minisandbox|mac_policy_register|kern_minimac' | head -15
echo "===STRINGS-CHECK==="
strings -a "$K" | grep -c 'AMFI' || true
