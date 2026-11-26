#!/bin/bash
echo "=== SpringBoard render pipelines ==="
grep -a 'render pipelines' /tmp/s176g.txt | grep SpringBoard | head -6
echo "=== iconservicesagent texture sizes mentioned ==="
grep -a 'iconservicesagent' /tmp/s176g.txt | grep -oE '[0-9]{2,3}x[0-9]{2,3}' | sort | uniq -c | sort -rn | head -8
</>
