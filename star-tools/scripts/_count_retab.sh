#!/bin/bash
OD=/root/star-build/xnu-deps/host/bin/llvm-objdump
[ -x "$OD" ] || OD=$(command -v llvm-objdump)
echo "objdump: $OD"
for B in /root/star26/s54/work/root/bin/input26-service /root/star26/s54/work/root/bin/metal_stubdev; do
  [ -f "$B" ] || continue
  echo "=== $B ($(stat -c%s "$B") bytes) ==="
  "$OD" -d "$B" 2>/dev/null > /tmp/dis.txt || continue
  tot=$(grep -cE '^\s+[0-9a-f]+:' /tmp/dis.txt)
  ret=$(grep -cE '\bret\s*$' /tmp/dis.txt)
  retab=$(grep -cE '\bretab\b|\bretaa\b' /tmp/dis.txt)
  braa=$(grep -cE '\bbraa\b|\bbrab\b|\bblraa\b|\bblrab\b' /tmp/dis.txt)
  ldra=$(grep -cE '\bldraa\b|\bldrab\b' /tmp/dis.txt)
  aut=$(grep -cE '\bautia\b|\bautib\b|\bautda\b|\bautdb\b|\bpacia\b|\bpacib\b|\bpacda\b|\bpacdb\b' /tmp/dis.txt)
  echo "  instructions: $tot"
  echo "  ret: $ret   retaa/retab: $retab   braa/blraa: $braa   ldraa: $ldra   pacia/autia(two-reg): $aut"
  if [ "$tot" -gt 0 ]; then
    python3 -c "print('  retab share of all insns: %.1f%%  (one trap every %.0f instructions)' % ($retab*100.0/$tot, $tot/max($retab,1)))"
  fi
done
