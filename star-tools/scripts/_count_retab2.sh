#!/bin/bash
OD=$(command -v llvm-objdump)
for B in /root/star26/s54/work/root/bin/input26-service; do
  "$OD" -d --no-show-raw-insn "$B" > /tmp/dis2.txt 2>/dev/null
  echo "=== $B ==="
  head -3 /tmp/dis2.txt | sed 's/^/  /'
  tot=$(grep -cE '^[[:space:]]*[0-9a-f]+:' /tmp/dis2.txt)
  retab=$(grep -cE '\bretaa\b|\bretab\b' /tmp/dis2.txt)
  braa=$(grep -cE '\bbraa\b|\bbrab\b|\bblraa\b|\bblrab\b' /tmp/dis2.txt)
  ldra=$(grep -cE '\bldraa\b|\bldrab\b' /tmp/dis2.txt)
  ret=$(grep -cE '\bret[[:space:]]*$' /tmp/dis2.txt)
  echo "  total insns: $tot   ret: $ret   retaa/retab: $retab   braa/blraa: $braa   ldraa: $ldra"
  python3 -c "
t=$tot; r=$retab; b=$braa
print('  trapping PAC insns: %d of %d = %.2f%%' % (r+b, t, (r+b)*100.0/max(t,1)))
print('  => one trap every %.1f instructions' % (t/max(r+b,1)))
"
done
