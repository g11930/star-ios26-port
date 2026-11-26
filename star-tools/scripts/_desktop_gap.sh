#!/bin/bash
OUT=/mnt/c/ios26/desktop_gap.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
T=/root/star26/hackios-xnu-userland/tools/apfs
R=/root/star26/s94/parts/ramdisk

e "===== 1) s94 ramdisk: graphics/Metal libs present? ====="
cd "$T" || exit 1
python3 apfs.py tree "$R" / 2>/dev/null | grep -iE 'libannibale.*(metal|air)|libOSMesa|metal' >> "$OUT"
echo "(end libs)" >> "$OUT"

e ""
e "===== 2) s94 log: GPU/display/metal service markers ====="
L=/mnt/c/ios26/s94-live3.bin
for s in "AnnibaleGPU" "IOAcceleratorES unavailable" "registration device=0" "registration completed device=1" "WindowServer" "first_frame" "swap" "commit" "fb_flip" "softpipe"; do
  echo -n "  $s = " >> "$OUT"; grep -a "$s" "$L" | tr -d '\0' | wc -l >> "$OUT"
done

e ""
e "===== 3) s94 cmdline: desktop-gate args ====="
for a in autounlock rwa_software metal applog ufs_write star_sbmetal; do
  echo -n "  $a = " >> "$OUT"; tr -d '\0' < /root/star26/s94/parts/cmdline | grep -o "$a=[^ ]*" >> "$OUT"
done

e ""
e "===== 4) 11-15 memory: desktop hard-gate verbatim ====="
sed -n '23,27p' /mnt/d/桌面/star-ios16-stable-documented-20261030/.workbuddy/memory/2026-11-15.md >> "$OUT"

e ""
e "===== 5) kernel source: GPU/display stub services ====="
grep -rln "AnnibaleGPU\|IOAcceleratorES" /root/star26/star-native/iokit /root/star26/star-native/bsd 2>/dev/null | head -10 >> "$OUT"

e ""
e "===== DONE ====="
echo "OK $(wc -c < "$OUT") bytes"
