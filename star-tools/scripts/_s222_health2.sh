#!/bin/bash
echo "=== npz ==="
ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l
echo "=== log tail ==="
tail -4 /root/proof_v2.log
echo "=== mem/swap ==="
free -h | head -3
echo "=== si/so (swap in/out per sec, vmstat 1 2) ==="
vmstat 1 2 | tail -1
echo "=== worker states / wchan ==="
for pid in $(pgrep -f 'zeta-venv/bin/python prove-zeta' | head -6); do
  st=$(awk '/^State:/{print $2}' /proc/$pid/status 2>/dev/null)
  wc=$(cat /proc/$pid/wchan 2>/dev/null)
  rss=$(awk '/^VmRSS:/{print $2}' /proc/$pid/status 2>/dev/null)
  echo "pid=$pid st=$st wchan=$wc rss=${rss}kB"
done
echo "=== load ==="
uptime
