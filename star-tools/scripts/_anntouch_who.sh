#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
echo "=== who starts anntouch ==="
grep -rn 'anntouch' $R/etc $R/annibale 2>/dev/null | head -10
echo "=== LaunchDaemons mentioning anntouch ==="
grep -rln 'anntouch' $R 2>/dev/null | head -10
echo "=== plists in annibale LaunchDaemons ==="
ls $R/annibale/LaunchDaemons 2>/dev/null | head -20
</