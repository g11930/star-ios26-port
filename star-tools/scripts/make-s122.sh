#!/bash
set -e
export THEOS=${THEOS:-$HOME/theos}
export PATH="/root/star-build/xnu-deps/host/bin:$THEOS/toolchain/linux/iphone/bin:$PATH"
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland
LDID=$THEOS/toolchain/linux/iphone/bin/ldid
DYN="xnu-clang -arch arm64 -isysroot $THEOS/sdks/iPhoneOS16.5.sdk -O1"

echo "===== 1) 编译 trialwake ====="
cp -f /mnt/d/桌面/star26-deps/scripts/trialwake.c $U/userland/src/tests/trialwake.c
cd $U/userland && $DYN -o obj/trialwake src/tests/trialwake.c
"$LDID" -S obj/trialwake && echo signed
file obj/trialwake | head -1
cp -f obj/trialwake $STG/bin/trialwake
chmod 755 $STG/bin/trialwake

echo "===== 2) rc.jobs 首行加入 trialwake ====="
python3 - <<'PY'
p = "/root/star26/s111/work/rootbuild/root/etc/rc.jobs"
s = open(p).read()
line = "/annibale/bin/trialwake\n"
if line not in s:
    open(p, "w").write(line + s)
print(open(p).read()[:120])
PY

echo "===== 3) 库 = s114 透传版 ====="
cp -f /root/libannibale-s114.dylib $STG/lib/libannibale.dylib
"$LDID" -S $STG/lib/libannibale.dylib && echo libsigned

echo "===== 4) 重打 ramdisk ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root10.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root10.apfs $BASE/parts/ramdisk

echo "===== 5) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s122-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s122-boot.img /root/star26/p2/p2-boot.img $BASE/s122-payload.bin 2>&1 | tail -1
cp -f $BASE/s122-boot.img /mnt/c/ios26/s122-boot.img
sha256sum /mnt/c/ios26/s122-boot.img
echo "===== DONE ====="
</bash>
