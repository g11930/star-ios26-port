#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
echo "--- bin ---"; ls $R/bin | head -20
echo "--- lib (annibale) ---"; ls $R/lib | head -20
echo "--- etc ---"; ls $R/etc | head -10
echo "--- private ---"; ls $R/private | head
echo "--- rc.jobs ---"; head -8 $R/etc/rc.jobs 2>/dev/null
</