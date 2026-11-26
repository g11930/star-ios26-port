#!/bin/bash
echo "=== build scripts for userland ==="
ls /mnt/d/桌面/star26-deps/scripts | grep -i 'user\|djbl\|metal\|lib' | head -20
echo "=== hackios-xnu-userland build entry ==="
ls /root/star26/hackios-xnu-userland | head -15
find /root/star26/hackios-xnu-userland -maxdepth 2 -name 'Makefile' -o -maxdepth 2 -name '*.sh' | head -10
</>
