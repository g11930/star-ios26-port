#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
echo "--- top ---"; ls $R | head
echo "--- annibale ---"; ls $R/annibale 2>/dev/null
echo "--- bin ---"; ls $R/annibale/bin 2>/dev/null
echo "--- notifyutil ---"; ls $R/usr/bin 2>/dev/null | grep -i 'notify\|ntf' | head
</