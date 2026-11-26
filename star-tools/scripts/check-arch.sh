#!/bin/bash
# Compare architectures: the rebuilt driver vs whatever copy of the shipped one is left.
echo "=== rebuilt (P22) ==="
file /root/star26/p22/libannibalemetal.dylib
echo "=== staging (P22) ==="
file /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
echo "=== any backups lying around ==="
ls -la /root/star26/p22/*.orig /root/star26/*.orig 2>/dev/null
find /root/star26 -name 'libannibalemetal*.dylib*' -size +100k 2>/dev/null | head -10
echo "=== the injector and the bundle ==="
file /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibale-sbmetal-experiment.dylib
file /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/AnnibaleMetal.bundle/AnnibaleMetal
echo "=== release archive? ==="
ls -la /root/star26/release/ 2>/dev/null | head
find /root /mnt/d/桌面/star26-deps -maxdepth 4 -name '*.zip' -o -maxdepth 4 -name '*.tar.gz' 2>/dev/null | head -10
