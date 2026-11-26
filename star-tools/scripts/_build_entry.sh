#!/bin/bash
B=/root/star26/hackios-xnu-userland/userland/build.sh
grep -n 'libannibalemetal\|dylib\|target\|usage' $B | head -20
echo "=== tools/mk scripts ==="
ls /root/star26/hackios-xnu-userland/tools | head -20
</>
