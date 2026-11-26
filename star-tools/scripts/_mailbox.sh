#!/bin/bash
cd /root/star26/star-native
echo "=== annibale_threads.c exports ==="
grep -n 'SYSCTL\|annibale.cmd\|cmd_mailbox\|kern_' bsd/dev/star/annibale_threads.c | head -20
echo "=== is it in conf/files ==="
grep -n 'annibale_threads' bsd/conf/files | head -3
echo "=== object present? ==="
ls -l BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/annibale_threads.o 2>/dev/null
</>
