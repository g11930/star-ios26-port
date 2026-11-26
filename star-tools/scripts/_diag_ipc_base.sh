#!/bin/bash
set +e
cd /root/star26/star-native || exit 1
echo "########## 1. our tree IPC diff vs baseline ac9718f (name-status) ##########"
git diff --name-status ac9718f -- osfmk/ipc/ osfmk/kern/ipc* bsd/kern/mach* 2>/dev/null | head -80
echo "########## 2. our tree IPC diff stat ##########"
git diff --stat ac9718f -- osfmk/ipc/ 2>/dev/null
echo "########## 3. dada.patch IPC files list ##########"
grep "^diff --git" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch 2>/dev/null | grep -i "osfmk/ipc\|osfmk/kern/ipc\|mach_msg\|mach_port\|ipc_" | head -60
echo "########## 4. full IPC diff vs baseline (unified, capped) ##########"
git diff ac9718f -- osfmk/ipc/ 2>/dev/null | head -300
