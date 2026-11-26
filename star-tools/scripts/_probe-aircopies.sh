#!/bin/bash
set -u
R=/root/star26/s42/work/root
echo "== all libannibaleair copies in image tree =="
find "$R" -name "libannibaleair*" 2>/dev/null | while read -r f; do
  echo "$(md5sum "$f") $(stat -c%s "$f") $f"
done
echo "== AnnibaleMetal.bundle =="
find "$R" -name "AnnibaleMetal*" -maxdepth 6 2>/dev/null | head -10
echo "== Extensions dir =="
ls -la "$R/System/Library/Extensions/" 2>/dev/null | head -20
echo "== flash overlay =="
ls -la "$R/flash/System/Library/Extensions/" 2>/dev/null | head -20
