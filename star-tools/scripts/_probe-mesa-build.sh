#!/bin/bash
set -u
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
echo "== git? =="
for d in $M /root/star26/hackios-xnu-kernel $M/src/compiler/air; do
  [ -d "$d/.git" ] && echo "git at $d"
done
git -C $M log --oneline -8 -- src/compiler/air/air_metal_lowering.inc 2>/dev/null | head
echo
echo "== other emitters of 'instruction type' =="
grep -rn "instruction type" $M/src/compiler/air/*.inc $M/src/compiler/air/*.c 2>/dev/null | head
echo
echo "== existing built dylibs in tree =="
find /root/star26/hackios-xnu-kernel -name 'libannibaleair*' -o -name 'libannibalemetal.dylib' 2>/dev/null | head -20
echo
echo "== deployed vs tree md5 =="
md5sum /root/star26/s41/work/root/lib/libannibaleair.dylib 2>/dev/null
for f in $(find /root/star26/hackios-xnu-kernel -name 'libannibaleair*' 2>/dev/null); do md5sum $f; done
echo
echo "== build scripts referencing mesa/air =="
grep -rn "libannibaleair" /root/star26/hackios-xnu-kernel --include=*.sh --include=*.py 2>/dev/null | head -10
ls -1 /root/star26/hackios-xnu-kernel/tools/*.sh 2>/dev/null | head -20
