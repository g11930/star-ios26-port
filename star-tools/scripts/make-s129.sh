#!/bin/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
export PATH="/root/star-build/xnu-deps/host/bin:$THEOS/toolchain/linux/iphone/bin:$PATH"
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) 重编 sbstall（SIGSTOP 版） ====="
xnu-clang -arch arm64 -isysroot $THEOS/sdks/iPhoneOS16.5.sdk -O1 \
  -o $STG/bin/sbstall /mnt/d/桌面/star26-deps/scripts/sbstall.c
chmod +x $STG/bin/sbstall
ldid -S $STG/bin/sbstall
ls -l $STG/bin/sbstall

echo "===== 2) rc.jobs 参数改成 150（去掉 step） ====="
python3 - <<'PY'
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
s = open(p).read().replace('/annibale/bin/sbstall 150 10', '/annibale/bin/sbstall 150')
open(p, 'w').write(s)
print(open(p).read().split('\n')[0])
PY

echo "===== 3) ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root17.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root17.apfs $BASE/parts/ramdisk

echo "===== 4) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s129-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s129-boot.img /root/star26/p2/p2-boot.img $BASE/s129-payload.bin 2>&1 | tail -1
cp -f $BASE/s129-boot.img /mnt/c/ios26/s129-boot.img
sha256sum /mnt/c/ios26/s129-boot.img
echo "===== DONE ====="
</bash>
