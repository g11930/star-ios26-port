#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
echo "--- rc.jobs ---"
cat $R/etc/rc.jobs
echo
echo "--- annsh in last live log ---"
strings -n 4 /mnt/c/ios26/live-ps.bin | grep -a 'annsh' | head -6
</>
