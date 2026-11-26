#!/bin/bash
echo "=== vendor focaltech sources anywhere ==="
find /root -maxdepth 4 -iname '*focal*' -o -maxdepth 4 -iname 'fts_ts*' 2>/dev/null | head -10
ls /root 2>/dev/null | head -20