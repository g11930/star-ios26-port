#!/bin/bash
echo "=== pass 1 ==="
for p in $(pgrep -f 'zeta-venv/bin/python prove-zeta' | head -20); do
  t=$(awk '{print $14}' /proc/$p/stat 2>/dev/null)
  echo "$p $t"
done > /tmp/cpu1.txt
cat /tmp/cpu1.txt | head -20
sleep 8
echo "=== pass 2 (after 8s) ==="
for p in $(pgrep -f 'zeta-venv/bin/python prove-zeta' | head -20); do
  t=$(awk '{print $14}' /proc/$p/stat 2>/dev/null)
  echo "$p $t"
done > /tmp/cpu2.txt
echo "=== deltas (jiffies/8s) ==="
while read p t1; do
  t2=$(awk -v p=$p '$1==p{print $2}' /tmp/cpu2.txt)
  if test -n "$t2"; then echo "pid=$p delta=$(( (t2-t1)/1 ))"; fi
done < /tmp/cpu1.txt
