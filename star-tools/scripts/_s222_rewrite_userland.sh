#!/bin/bash
set -e
cd /root/dsc26_zeta_scripts
PY=/root/star26/zeta-venv/bin/python
mkdir -p /root/ul26_out
for f in dyld launchd; do
  in=/root/ul26/usr/$f
  out=/root/ul26_out/$f
  rep=/root/ul26_out/report-$f.json
  echo "=== rewriting $f ==="
  $PY rewrite-zeta-userland.py --input "$in" --output "$out" \
    --apple-trust-cache /root/dsc26_work/trust_static.im4p \
    --apple-trust-cache /root/dsc26_work/trust_systemcrytex.im4p \
    --report "$rep" 2>&1 | tail -12
done
echo "=== done ==="
ls -la /root/ul26_out/
