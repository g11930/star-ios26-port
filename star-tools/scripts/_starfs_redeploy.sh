#!/bin/bash
# Deploy starfs, handling the case where the phone is currently sitting in xnuloader
# (the iOS loader's fastboot server) instead of Android.
export MSYS_NO_PATHCONV=1
A=/mnt/d/桌面/adb-fastboot/adb.exe
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
STAGE=/mnt/c/ios26/starfs-mod
SRC=/mnt/d/桌面/star26-deps/module/starfs/build
DEV=/data/local/tmp/starfs-mod

echo "=== state ==="
"$A" start-server >/dev/null 2>&1
p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i '^product:' | head -1)
echo "fastboot: ${p:-none}"

case "$p" in
  *xnuloader*)
    echo "=== rebooting out of xnuloader ==="
    timeout 15 "$F" -s xnuloader reboot 2>&1 | tr -d '\r' | tail -2
    ;;
esac

echo "=== wait for android ==="
ok=0
for i in $(seq 1 45); do
  sleep 2
  ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
  if [ "$ad" -ge 1 ]; then echo "android online after $((i*2))s"; ok=1; break; fi
done
if [ "$ok" != "1" ]; then
  echo "ABORT: android did not come back"
  "$A" devices 2>&1 | tr -d '\r'
  exit 2
fi

echo "=== stage ==="
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -r "$SRC"/. "$STAGE"/

echo "=== push ==="
"$A" shell "rm -rf $DEV" >/dev/null 2>&1
"$A" push "C:/ios26/starfs-mod" /data/local/tmp/ 2>&1 | tr -d '\r' | tail -1

echo "=== install ==="
"$A" shell "su -c 'sh $DEV/install.sh'" 2>&1 | tr -d '\r' | head -8

echo "=== binary md5 on device ==="
"$A" shell "su -c 'md5sum /data/adb/ksu/bin/starfs /data/adb/modules/starfs/starfs'" 2>&1 | tr -d '\r'
md5sum /mnt/d/桌面/star26-deps/module/starfs/jni/starfs
echo "=== DONE ==="
