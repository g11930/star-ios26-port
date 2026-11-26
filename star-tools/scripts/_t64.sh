#!/bin/bash
sed -n '5440,5500p' /root/star26/star-native/bsd/vfs/vfs_syscalls.c
echo "=== kern_minimac 40-110 ==="
sed -n '40,110p' /root/star26/star-native/bsd/kern/kern_minimac.c