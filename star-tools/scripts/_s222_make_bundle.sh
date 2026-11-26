#!/bin/bash
set -e
cd /root/dsc26_zeta_scripts
PY=/root/star26/zeta-venv/bin/python
$PY make-zeta-trust-bundle.py \
  --apple-trust-cache /root/dsc26_work/trust_static.im4p \
  --apple-trust-cache /root/dsc26_work/trust_systemcrytex.im4p \
  --rewrite-report /root/dsc26_work/rewrite-report.json \
  --rewrite-report /root/ul26_out/report-dyld.json \
  --rewrite-report /root/ul26_out/report-launchd.json \
  --output /root/dsc26_work/zeta-trust-bundle.bin \
  --report /root/dsc26_work/zeta-trust-bundle-report.json
echo "=== bundle built ==="
ls -la /root/dsc26_work/zeta-trust-bundle*
cat /root/dsc26_work/zeta-trust-bundle-report.json
