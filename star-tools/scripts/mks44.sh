#!/bin/bash
# mks44.sh -- s44 = s43 + restore the inject.conf line that s36 removed.
#
# s36 tried "no libannibale-sbmetal-experiment.dylib injection" as an experiment,
# concluded "no effect -> suspect cleared", but never put the line back.  Every
# round since (s37..s43) copies the previous root, so backboardd has had NO
# annibale code for eight boots.  That is why:
#   * "annibale lib loaded pid %d name %s" never appears (libannibale.dylib's
#     first unconditional printf),
#   * "StartWindowServer" never appears even though backboardd lives to 900 s
#     with a stable pid and zero new crash reports.
# The original file (s34, mtime 2023-05-12, 766 bytes, 6 lines) is restored
# byte for byte; that is the whole change.
set -e
mkdir -p /root/star26/s44/work
rm -rf /root/star26/s44/work/root
cp -a /root/star26/s43/work/root /root/star26/s44/work/root

SRC=/root/star26/s34/work/root/etc/inject.conf
DST=/root/star26/s44/work/root/etc/inject.conf
echo "== inject.conf before (s43) =="
stat -c '%s bytes, %n' "$DST"
md5sum "$DST"
echo "== restoring from s34 =="
stat -c '%s bytes, %n' "$SRC"
md5sum "$SRC"
cp -f "$SRC" "$DST"
echo "== after =="
stat -c '%s bytes' "$DST"
md5sum "$DST"
cat "$DST"
echo "== sanity: libs referenced must all exist =="
while read -r lib _rest; do
  [ -z "$lib" ] && continue
  case "$lib" in \#*) continue;; esac
  rel="${lib#/annibale}"
  if [ -f "/root/star26/s44/work/root$rel" ]; then
    echo "  ok   $lib"
  else
    echo "  MISSING $lib  (looked for root$rel)"
  fi
done < "$DST"

cd /root/star26/s44/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s44/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s44 s43 "" loader_return_after=900 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s44 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s44/parts/cmdline
echo
ls -l /root/star26/s44/s44-boot.img
