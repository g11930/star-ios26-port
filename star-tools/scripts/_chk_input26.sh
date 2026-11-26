#!/bin/bash
for f in /root/star26/baseline/s197parts/ramdisk /root/star26/baseline/s197parts/rdimage /root/star26/hackios-xnu-userland/userland/obj/input26-service; do
  if [ ! -f "$f" ]; then echo "== $f  (missing)"; continue; fi
  echo "== $f  $(stat -c%s "$f") bytes"
  for s in "services registered" "sample type" "standalone pid" "qos thread requested" "registration failed" "did not open"; do
    n=$(strings -a "$f" | grep -c "$s")
    printf '   %-24s %s\n' "$s" "$n"
  done
done
