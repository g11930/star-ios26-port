#!/bin/bash
echo "=== killing thrashing proof ==="
for p in $(pgrep -f 'zeta-venv/bin/python prove-zeta-dyld-cache.py'); do
  kill -9 "$p" 2>/dev/null && echo "killed $p"
done
sleep 3
echo "=== remaining ==="
pgrep -af 'prove-zeta-dyld-cache.py' || echo "none"
echo "=== mem after ==="
free -h | head -3
