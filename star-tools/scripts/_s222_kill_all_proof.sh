#!/bin/bash
PIDS=$(pgrep -f 'zeta-venv/bin/python prove-zeta-dyld-cache.py')
for p in $PIDS; do
  kill -9 "$p" 2>/dev/null && echo "killed $p"
done
sleep 3
echo "remaining: $(pgrep -f 'zeta-venv/bin/python prove-zeta-dyld-cache.py' | wc -l)"
free -h | head -2
