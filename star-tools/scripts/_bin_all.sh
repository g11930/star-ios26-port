#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
ls $R/bin
echo "--- sources for notify poster ---"
grep -rn 'notify_post' /root/star26/hackios-xnu-userland/userland/src/*.c /root/star26/hackios-xnu-userland/userland/src/**/*.c 2>/dev/null | head -6
find /root/star26/hackios-xnu-userland/userland -maxdepth 3 -name '*.c' | xargs grep -ln 'notify_post' 2>/dev/null | head -6
</