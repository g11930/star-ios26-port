#!/bin/bash
find /root/star26 -maxdepth 6 -name 'sb_metal_experiment.m' 2>/dev/null | head -3
find /root/star26 -maxdepth 5 -type d -name inject 2>/dev/null | head -5
echo "--- built dylibs ---"
ls -l /root/star26/s111/work/rootbuild/root/annibale/lib 2>/dev/null | head -12
</