#!/bin/bash
echo "=== WSL distros ==="
wsl.exe -l -v
echo "=== key files ==="
wsl.exe -d Ubuntu-24.04 -- bash -c 'ls -la /root/star26/star-native/osfmk/arm64/sleh.c /root/star26/star-native/bsd/kern/mach_loader.c 2>&1; echo "---git---"; cd /root/star26/star-native && git status --short | head -30'
