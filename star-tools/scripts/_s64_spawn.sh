#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "=== SPWNVAL lines ==="
strings -a "$F" | grep "SPWNVAL" | head -60
echo
echo "=== SPWNRET lines ==="
strings -a "$F" | grep "SPWNRET" | head -60
echo
echo "=== xpcproxy count ==="
strings -a "$F" | grep -c "loading /usr/libexec/xpcproxy"
echo "=== cfprefsd/configd/securityd exec count ==="
for s in cfprefsd configd securityd; do
  echo -n "$s="
  strings -a "$F" | grep -c "loading.*$s"
done
