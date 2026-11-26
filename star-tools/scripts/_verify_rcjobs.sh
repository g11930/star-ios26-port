#!/bin/bash
R=/root/star26/s111/work/rootbuild/root/etc
echo "=== now ==="
cat -n $R/rc.jobs
echo "=== backup ==="
ls -l $R/rc.jobs.s171
echo "=== counts ==="
echo "anntouch lines now: $(grep -c 'anntouch' $R/rc.jobs)"
echo "wait 200 now:       $(grep -c 'wait 200' $R/rc.jobs)"
</>
