#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
ls $D | head -20
echo "=== pipecache inc size ==="
wc -l $D/annibalemetal_pipecache.inc
echo "=== disk path / cache dir ==="
grep -n -i 'path\|disk\|/var\|cache_dir\|mkdir\|fopen\|write' $D/annibalemetal_pipecache.inc | head -20
</>
