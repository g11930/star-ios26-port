#!/bin/bash
L=/mnt/c/ios26/s62-staged.bin
echo "=== ALL EXECDBG cputype/subtype distribution (whole s62 log) ==="
strings "$L" | grep -oE 'EXECDBG: loading [^ ]+ cputype [0-9a-f]+ subtype [0-9a-f]+' | \
  sed -E 's/.*cputype ([0-9a-f]+) subtype ([0-9a-f]+)/cputype=\1 subtype=\2/' | sort | uniq -c | sort -rn
echo ""
echo "=== arm64e (subtype 80000002) binaries ==="
strings "$L" | grep 'subtype 80000002' | grep -oE 'loading [^ ]+' | sed 's/loading //' | sort -u | head -40
echo ""
echo "=== arm64 (subtype 0) binaries ==="
strings "$L" | grep 'subtype 0 ' | grep -oE 'loading [^ ]+' | sed 's/loading //' | sort -u | head -40
echo ""
echo "=== key daemons arch ==="
for s in launchd init backboardd SpringBoard logd xpcproxy cfprefsd configd securityd; do
  printf '%-14s ' "$s"
  strings "$L" | grep "loading [^ ]*$s " | grep -oE 'cputype [0-9a-f]+ subtype [0-9a-f]+' | sort -u | tr '\n' ' '
  echo
done
echo ""
echo "=== root/cryptex mount lines ==="
strings "$L" | grep -iE 'cryptex|ufs_darwin|ufs,c=|mount.*root|root_apfs|darwin,c=' | head -20
