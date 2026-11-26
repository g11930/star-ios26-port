#!/bin/bash
set -u
echo "== find sources =="
find /root/star26 -maxdepth 6 \( -name "lsprobe.c" -o -name "lsprobe*.c" -o -name "mk-lsprobe*" -o -name "mk-starcat*" \) 2>/dev/null | head -20
echo "== rc.jobs in s42 =="
for f in /root/star26/s42/work/root/etc/rc.jobs /root/star26/s42/work/root/sbin/rc.jobs /root/star26/s42/work/root/annibale/etc/rc.jobs; do
  [ -f "$f" ] && echo "FILE $f" && cat "$f"
done
echo "== search rc.jobs anywhere =="
find /root/star26/s42/work/root -maxdepth 4 -name "rc*" -type f 2>/dev/null | head -10
