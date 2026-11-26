#!/bin/bash
strings -n 5 /mnt/c/ios26/s139e-live.bin > /tmp/s139e.txt
wc -c /mnt/c/ios26/s139e-live.bin
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s139e-frame.raw /mnt/c/ios26/s139e-frame.png
for k in 'start window server' 'Initializing CAWindowServer' 'swap #' 'P34:' 'CAWindowServerDisplay' 'Metal failed'; do
  printf '%-28s %s\n' "$k" "$(grep -ac -- "$k" /tmp/s139e.txt)"
done
echo "=== tail ==="
grep -a '^2025' /tmp/s139e.txt | tail -2
</bash>
