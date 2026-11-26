#!/bin/bash
A=/root/ref2/annibale-userland
O=/root/star26/hackios-xnu-userland
echo "===== 1. mkjobs.py diff (stat) ====="
diff -q "$A/userland/mkjobs.py" "$O/userland/mkjobs.py" 2>&1
diff "$A/userland/mkjobs.py" "$O/userland/mkjobs.py" 2>/dev/null | head -30
echo
echo "===== 2. mkcache.py diff ====="
diff "$A/userland/mkcache.py" "$O/userland/mkcache.py" 2>/dev/null | head -20
echo
echo "===== 3. rc.launchd diff ====="
diff "$A/userland/rc.launchd" "$O/userland/rc.launchd" 2>/dev/null | head -15
echo
echo "===== 4. build.sh: job list / LaunchAngels ====="
grep -n 'LaunchAngel\|LaunchDaemons' "$A/userland/build.sh" | head -10
echo "---- ours:"
grep -n 'LaunchAngel\|LaunchDaemons' "$O/userland/build.sh" | head -10
