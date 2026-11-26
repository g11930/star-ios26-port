#!/bin/bash
set -u
for f in \
  /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/etc/inject.conf \
  /root/star26/p37/work/rootbuild/root/etc/inject.conf \
  /root/star26/p38/work/rootbuild/root/etc/inject.conf \
  /root/star26/p18/work/root/etc/inject.conf \
  /root/star26/p2/work/root/etc/inject.conf \
  /root/star26/p36/work/rootbuild/root/etc/inject.conf ; do
  if [ -f "$f" ]; then
    echo "=== $f  size=$(stat -c%s "$f")"
    cat "$f"
    echo
  fi
done
echo "== does anything reference libannibale.dylib for backboardd at all? =="
grep -rn "libannibale\.dylib" /root/star26/hackios-xnu-userland/userland/src/ 2>/dev/null | head -10
grep -rn "backboardd" /root/star26/hackios-xnu-userland/userland/src/boot/*.c 2>/dev/null | head -10
