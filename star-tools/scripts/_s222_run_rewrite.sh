#!/bin/bash
set -e
SCRIPTS=/root/dsc26_zeta_scripts
CACHE=/root/dsc26/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64e
PROOF=/root/dsc26_proof
OUT=/root/dsc26_rewritten
WORK=/root/dsc26_work
PY=/root/star26/zeta-venv/bin/python

echo "=== proof totals ==="
cat "$PROOF/summary.json" | "$PY" -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["totals"], indent=1))'

rm -rf "$OUT"
cd "$SCRIPTS"
"$PY" rewrite-zeta-dyld-cache.py \
  --cache "$CACHE" \
  --proof "$PROOF" \
  --output "$OUT" \
  --apple-trust-cache "$WORK/trust_static.im4p" \
  --apple-trust-cache "$WORK/trust_systemcrytex.im4p" \
  --page-shift 12 \
  --report "$WORK/rewrite-report.json" 2>&1

echo "=== rewrite done ==="
du -sh "$OUT"
cat "$WORK/rewrite-report.json" | "$PY" -c 'import json,sys; r=json.load(sys.stdin); print(json.dumps({k:r[k] for k in ("edits","files_changed","page_shift")}, indent=1))'
