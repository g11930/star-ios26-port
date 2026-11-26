#!/bin/bash
B=/root/star26/hackios-xnu-userland/userland/build.sh
grep -n 'DYN=\|IOS=\|xcrun\|clang' $B | head -12
echo "=== ios26 dir ==="
ls /root/star26/hackios-xnu-userland/ios26 | head -8
</>
