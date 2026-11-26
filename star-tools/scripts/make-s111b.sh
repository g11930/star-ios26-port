#!/bash
set -e
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) inject.conf = s110 原始 + libannibale 一行 ====="
cat > $STG/etc/inject.conf <<'EOF'
/annibale/lib/liblogdtrace.dylib logd
/annibale/lib/liblogdtrace.dylib logd
/annibale/lib/libsbtrace.dylib SpringBoard backboardd iconservicesagent MercuryPosterExtension
/annibale/lib/libannibale-sb26.dylib SpringBoard PosterBoard MercuryPosterExtension Preferences lsd wifid
/annibale/lib/libannibale-media.dylib cameracaptured mediaserverd
/annibale/lib/libannibale-vt.dylib videocodecd mediaserverd com.apple.WebKit.GPU video_decode_test video_player_test
/annibale/lib/libannibale-app.dylib Calculator MobileNotes Reminders MobileCal Preferences MobileSMS systemstatusd Weather weatherd Maps geod MobileSafari com.apple.WebKit.Networking com.apple.WebKit.WebContent nsurlsessiond chronod
/annibale/lib/libannibale-ax.dylib SpringBoard Preferences MobileSafari Weather MobileSMS MobileNotes MobileMail MobileCal Files
/annibale/lib/libannibale.dylib backboardd
EOF
cat $STG/etc/inject.conf

echo "===== 2) 确认 libannibale.dylib 在 staging lib 里 ====="
ls -l $STG/lib/libannibale.dylib $STG/lib/libsbtrace.dylib $STG/lib/liblogdtrace.dylib

echo "===== 3) mkapfs 重建 root.apfs ====="
python3 $U/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root2.apfs "annibale=$STG" 2>&1 | tail -3
ls -l $BASE/root2.apfs

echo "===== 4) 换上 ramdisk 并重打包 ====="
cp -f $BASE/root2.apfs $BASE/parts/ramdisk
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s111-payload.bin \
  loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage \
  --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -2
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s111-boot.img /root/star26/p2/p2-boot.img $BASE/s111-payload.bin 2>&1 | tail -2
cp -f $BASE/s111-boot.img /mnt/c/ios26/s111-boot.img
sha256sum /mnt/c/ios26/s111-boot.img
echo "===== DONE ====="
</bash>
