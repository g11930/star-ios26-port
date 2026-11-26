#!/bin/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) rc.jobs 去掉 sbstall ====="
python3 - <<'PY'
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read()
lines = [l for l in s.split('\n') if 'sbstall' not in l]
open(p, 'w').write('\n'.join(lines))
print(open(p).read().split('\n')[0])
PY

echo "===== 2) 让 runningboardd 排到缓存最前 ====="
python3 - <<'PY'
import os, shutil, glob
src = '/root/star26/s111/work/rootbuild/root/LaunchDaemons'
dst = '/tmp/jobs-rbfirst'
shutil.rmtree(dst, ignore_errors=True)
os.makedirs(dst)
for p in glob.glob(src + '/*.plist'):
    n = os.path.basename(p)
    if n == 'com.apple.runningboardd.plist':
        n = '0.runningboardd.plist'
    shutil.copy2(p, os.path.join(dst, n))
print('copied', len(glob.glob(dst + '/*.plist')))
PY

cd $U/userland
cp -f $STG/xpc/launchd.plist /tmp/launchd-base6.plist
./mkcache.py /tmp/launchd-base6.plist /tmp/jobs-rbfirst /tmp/launchd-new6.plist
cp -f /tmp/launchd-new6.plist $STG/xpc/launchd.plist
python3 - <<'PY'
import plistlib
c = plistlib.load(open('/root/star26/s111/work/rootbuild/root/xpc/launchd.plist','rb'))
keys = list(c['LaunchDaemons'])
print('jobs:', len(keys))
print('first 3 keys:', keys[:3])
print('runningboardd present:', [k for k in keys if 'runningboardd' in k])
PY

echo "===== 3) ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root18.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root18.apfs $BASE/parts/ramdisk

echo "===== 4) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s130-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s130-boot.img /root/star26/p2/p2-boot.img $BASE/s130-payload.bin 2>&1 | tail -1
cp -f $BASE/s130-boot.img /mnt/c/ios26/s130-boot.img
sha256sum /mnt/c/ios26/s130-boot.img
echo "===== DONE ====="
</bash>
