#!/bin/bash
cd /mnt/d/桌面/star26-deps/scripts
python3 -c 'import PIL; print("PIL", PIL.__version__)'
for t in a b c; do
  echo "=== $t ==="
  python3 raw2png.py "/mnt/c/ios26/s175${t}-frame.raw" 2>&1 | head -3
done
