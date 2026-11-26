#!/bin/bash
# s215 = s208 (known bootable base) with ONE change: ramdisk's libannibale-sb26.dylib
# replaced by K90 v0.2.1's (CoverSheet-native unlock, no method swizzling).
# Everything else (kernel, cmdline, loader, rdimage, memsize, identity, all other ramdisk files)
# stays byte-identical to s208.
set -e
B=/root/star26/baseline/s215parts
S208=/root/star26/baseline/s208parts
STG=/tmp/s215stg
MKAPFS=/root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py
K90DYLIB=/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib/libannibale-sb26.dylib
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py

mkdir -p "$B" "$STG"

echo "=== [1] copy all s208 components except ramdisk ==="
for name in loader.efi rdimage memsize identity kernel cmdline cmdline-base; do
  [ -f "$S208/$name" ] && cp -f "$S208/$name" "$B/$name"
done
# s208parts has no cmdline file (s208 pack built it inline). Extract verbatim from s208 payload
# so s215's cmdline is byte-identical to s208's.
if [ ! -f "$B/cmdline" ]; then
  python3 - <<'PY'
d=open("/root/star26/baseline/s208parts/s208-payload.bin","rb").read()
i=d.find(b"debug=0x10e"); j=d.find(b"\x00",i)
assert i>=0 and j>i
cl=d[i:j]
open("/root/star26/baseline/s215parts/cmdline","wb").write(cl)
open("/root/star26/baseline/s215parts/cmdline-base","wb").write(cl)
print("  extracted cmdline from s208 payload: %d bytes"%len(cl))
PY
fi

echo "=== [2] build staging tree from s208 ramdisk ==="
rm -rf "$STG"; mkdir -p "$STG"
export PYTHONPATH=/mnt/d/桌面/star26-deps/tools/apfs
python3 /mnt/d/桌面/star26-deps/scripts/apfs-extract.py "$S208/ramdisk" "$STG" 2>&1 | tail -1

echo "=== [3] snapshot hashes of ALL original ramdisk files (for single-variable verify) ==="
python3 - <<'PY'
import hashlib, os
h={}
for root,dirs,files in os.walk("/tmp/s215stg"):
    for f in files:
        fp=os.path.join(root,f); rel=os.path.relpath(fp,"/tmp/s215stg")
        if os.path.islink(fp):
            h[rel]="SYMLINK:"+os.readlink(fp)   # dangling symlink: record target only
        else:
            h[rel]=hashlib.sha256(open(fp,"rb").read()).hexdigest()
import json
json.dump(h,open("/tmp/s208_files.sha256","w"),indent=0)
print("  snapshotted %d files"%len(h))
PY

echo "=== [4] replace ONLY libannibale-sb26.dylib with K90 v0.2.1 build ==="
stat -c "  old: %s %n" "$STG/lib/libannibale-sb26.dylib"
cp -f "$K90DYLIB" "$STG/lib/libannibale-sb26.dylib"
stat -c "  new: %s %n" "$STG/lib/libannibale-sb26.dylib"

echo "=== [5] single-variable verify: only sb26 dylib changed in tree ==="
python3 - <<'PY'
import hashlib, os, json
old=json.load(open("/tmp/s208_files.sha256"))
new={}
for root,dirs,files in os.walk("/tmp/s215stg"):
    for f in files:
        fp=os.path.join(root,f); rel=os.path.relpath(fp,"/tmp/s215stg")
        if os.path.islink(fp):
            new[rel]="SYMLINK:"+os.readlink(fp)
        else:
            new[rel]=hashlib.sha256(open(fp,"rb").read()).hexdigest()
assert set(old)==set(new), "FILE SET CHANGED: %s"%(set(old)^set(new))
diff=[k for k in old if old[k]!=new[k]]
print("  changed files:",diff)
assert diff==["lib/libannibale-sb26.dylib"], "UNEXPECTED CHANGED FILES: %s"%diff
print("  VERIFY PASS: only libannibale-sb26.dylib differs")
PY

echo "=== [6] repack ramdisk (mkapfs -z --plain fw, annibale=STG) ==="
python3 "$MKAPFS" -z --plain fw -o "$B/ramdisk" "annibale=$STG" 2>&1 | tail -2
stat -c "  ramdisk: %s %n" "$B/ramdisk"

echo "=== [7] guard: kernel/cmdline/loader etc. match s208 ==="
for name in loader.efi rdimage memsize identity kernel; do
  A=$(md5sum "$S208/$name"|cut -d' ' -f1); C=$(md5sum "$B/$name"|cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "CHANGED vs s208: $name"; exit 1; }
done
python3 - <<'PY'
a=open("/root/star26/baseline/s208parts/s208-payload.bin","rb").read()
i=a.find(b"debug=0x10e"); j=a.find(b"\x00",i); cl208=a[i:j]
cl215=open("/root/star26/baseline/s215parts/cmdline","rb").read()
assert cl208==cl215, "CMDLINE CHANGED vs s208"
print("  cmdline identical to s208 (%d bytes, pac_patch=0)"%len(cl215))
assert b"pac_patch=0" in cl215
PY
echo "  all non-ramdisk components identical to s208"

echo "=== [8] repack payload + reseal image ==="
CL=$(tr -d '\0' < "$B/cmdline")
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s215-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s215-boot.img /root/star26/p2/p2-boot.img "$B/s215-payload.bin" 2>&1 | tail -1

echo "=== [9] final checks ==="
python3 "$X" /mnt/c/ios26/s215-boot.img 2>&1 | grep -E 'cmdline|kernel' | head -3
sha256sum /mnt/c/ios26/s215-boot.img
stat -c "  image: %s %n" /mnt/c/ios26/s215-boot.img
echo "=== DONE s215 ==="
