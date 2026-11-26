#!/bin/bash
set -u
NEW=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/src/gallium/drivers/freedreno/libannibaleair.dylib
OLD=/root/star26/s41/work/root/lib/libannibaleair.dylib
llvm-nm -gU "$NEW" 2>/dev/null | awk '{print $NF}' | sort > /tmp/e_new.txt
llvm-nm -gU "$OLD" 2>/dev/null | awk '{print $NF}' | sort > /tmp/e_old.txt
echo "exports new=$(wc -l < /tmp/e_new.txt) old=$(wc -l < /tmp/e_old.txt)"
echo "== only in new (missing from old) =="
comm -23 /tmp/e_new.txt /tmp/e_old.txt | head -30
echo "count=$(comm -23 /tmp/e_new.txt /tmp/e_old.txt | wc -l)"
echo
echo "== only in old (would break libannibalemetal if it dlsyms) =="
comm -13 /tmp/e_new.txt /tmp/e_old.txt | head -30
echo "count=$(comm -13 /tmp/e_new.txt /tmp/e_old.txt | wc -l)"
echo
echo "== cpusubtype =="
for f in "$NEW" "$OLD"; do
  echo "--- $f"
  python3 - "$f" <<'PY'
import sys,struct
p=sys.argv[1]; d=open(p,'rb').read()
magic,ct,cs,ft,nc,sz,fl=struct.unpack_from('<IiiIIII',d,0)
print("magic=%#x cputype=%d cpusubtype=%#x (%d) filetype=%d ncmds=%d"%(magic,ct,cs,cs & 0xff,ft,nc))
PY
done
