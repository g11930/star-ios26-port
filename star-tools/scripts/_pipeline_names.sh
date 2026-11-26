#!/bin/bash
echo "=== pipeline lines ==="
grep -a -oE 'pipeline 0x[0-9a-f]+ is [A-Za-z0-9_]+' /tmp/s176g.txt | awk '{print $NF}' | sort | uniq -c | sort -rn | head -12
echo "=== render pipeline mentions ==="
grep -a -i 'render pipeline' /tmp/s176g.txt | head -4
</>
