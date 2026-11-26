#!/bin/bash
set -e
BASE=/root/star26/s111
python3 - <<'PY'
p = '/root/star26/s111/parts/cmdline'
s = open(p).read().strip()
w = [x for x in s.split() if x != 'rwa_software=1']
open(p, 'w').write(' '.join(w))
print('cmdline now', len(' '.join(w)))
PY
N=140 bash /mnt/d/桌面/star26-deps/scripts/make-s135.sh
sed 's/TAG=s131/TAG=s140/' /mnt/d/桌面/star26-deps/scripts/_s131_flash.sh > /mnt/d/桌面/star26-deps/scripts/_s140_flash.sh
python3 /mnt/d/桌面/star26-deps/scripts/_patch_wait.py /mnt/d/桌面/star26-deps/scripts/_s140_flash.sh
</bash>
