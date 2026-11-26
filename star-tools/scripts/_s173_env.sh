#!/bin/bash
echo "=== annsh output ==="
grep -a -E 'annsh|setenv|kern.annibale.env' /tmp/s173.txt | head -20
echo "=== restart evidence ==="
grep -a -E 'restart|SIGKILL|SpringBoard\[' /tmp/s173.txt | head -10
</>
