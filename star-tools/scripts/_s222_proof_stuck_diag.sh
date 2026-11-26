#!/bin/bash
echo "=== worker states + wchan ==="
for pid in $(pgrep -f 'prove-zeta-dyld-cache.py' | head -20); do
  st=$(awk '/^State:/{print $2}' /proc/$pid/status 2>/dev/null)
  wc=$(cat /proc/$pid/wchan 2>/dev/null)
  ut=$(awk '/^Threads:/{print $2}' /proc/$pid/status 2>/dev/null)
  vsz=$(awk '/^VmRSS:/{print $2" "$3}' /proc/$pid/status 2>/dev/null)
  echo "pid=$pid state=$st wchan=$wc threads=$ut rss=$vsz"
done
echo "=== children of each worker (llvm-mc etc) ==="
for pid in $(pgrep -f 'prove-zeta-dyld-cache.py' | head -20); do
  kids=$(pgrep -P $pid 2>/dev/null | tr '\n' ' ')
  if test -n "$kids"; then
    echo "parent=$pid children=$kids"
    for k in $kids; do
      echo "   child $k: $(cat /proc/$k/comm 2>/dev/null) state=$(awk '/^State:/{print $2}' /proc/$k/status 2>/dev/null) wchan=$(cat /proc/$k/wchan 2>/dev/null)"
    done
  fi
done
echo "=== mem ==="
free -h | head -2
echo "=== load ==="
uptime
echo "=== dmesg oom (last 5) ==="
dmesg 2>/dev/null | grep -iE 'oom|killed process' | tail -5
