#!/bin/bash
set -e
cd /root/dsc26_zeta_scripts
PY=/root/star26/zeta-venv/bin/python
$PY replace-zeta-root-files.py \
  --container /root/os26_new.dmg \
  --volume LuckG23G90.V57OS \
  --file /usr/lib/dyld /root/ul26_out/dyld /root/ul26_out/report-dyld.json \
  --file /sbin/launchd /root/ul26_out/launchd /root/ul26_out/report-launchd.json \
  --report /root/os26_new_replacement.json
echo "=== replacement OK ==="
