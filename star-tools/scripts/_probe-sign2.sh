#!/bin/bash
set -u
D=/root/star26/hackios-xnu-userland/tools
echo "== mesa tool dir =="
ls -la $D/mesa | head -20
echo
echo "== mk-mesa.sh head =="
sed -n '1,60p' $D/mk-mesa.sh
echo
echo "== signing mentions =="
grep -rn "codesign\|ldid\|CODE_SIGNATURE" $D/mk-mesa.sh $D/mesa/*.sh 2>/dev/null | head -20
echo
echo "== which tools exist =="
for t in ldid codesign rcodesign; do
  p=$(command -v "$t" 2>/dev/null); echo "$t = ${p:-none}"
done
