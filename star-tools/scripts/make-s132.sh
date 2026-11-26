#!/bin/bash
set -e
BASE=/root/star26/s111
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837

echo "===== 1) kernel 换成带 adreno8 的新内核 ====="
cp -f $BASE/parts/kernel $BASE/parts/kernel.pre-gpu
cp -f $K $BASE/parts/kernel
ls -la $BASE/parts/kernel
strings -n 6 $BASE/parts/kernel | grep -c 'RBBM_GPU_ID' || true

echo "===== 2) cmdline: 去 fbpaint, 加 GPU 四件 ====="
python3 - <<'PY'
p = '/root/star26/s111/parts/cmdline'
s = open(p).read().strip()
words = [w for w in s.split() if not w.startswith('fbpaint')]
for w in ('gpu=1', 'metal=1', 'camtl=1', 'metal_profile=1', 'adreno_keep=1'):
    key = w.split('=')[0]
    words = [x for x in words if not x.startswith(key + '=')]
    words.append(w)
open(p, 'w').write(' ' .join(words))
print(len(' '.join(words)), ' '.join(words)[:400])
PY

echo "===== 3) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s132-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s132-boot.img /root/star26/p2/p2-boot.img $BASE/s132-payload.bin 2>&1 | tail -1
cp -f $BASE/s132-boot.img /mnt/c/ios26/s132-boot.img
sha256sum /mnt/c/ios26/s132-boot.img
echo "===== DONE ====="
</bash>
