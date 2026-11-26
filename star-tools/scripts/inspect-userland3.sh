#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== build.sh references to annibalemetal / drawable ==="
grep -n 'annibalemetal\|annibaledrawable\|userland-driver\|LIBRARY\|-install_name\|codesign' "$U"/userland/build.sh | head -40
echo "=== any build script near userland-driver ==="
find /root/star26/hackios-xnu-kernel/tools -maxdepth 2 -name '*.sh' -o -maxdepth 2 -name 'Makefile' | head -20
echo "=== mk scripts ==="
ls /root/star26/hackios-xnu-kernel/tools/*.sh 2>/dev/null | head -20
