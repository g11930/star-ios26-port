#!/bin/bash
OBJ=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/annibale_adreno.o
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=$K.unstripped.noctf
echo "=== timestamps ==="
stat -c '%y %s %n' "$OBJ" "$K" "$NU" 2>/dev/null
echo
echo "=== source mtime ==="
stat -c '%y %n' /root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo
echo "=== new log strings in the OBJECT ==="
for s in 'speeds, %u..%u MHz; votes' 'the speed wanted: %u MHz (speed %u of %u)' 'speed %u of %u'; do
  printf '%-45s obj=%s  kernel=%s\n' "$s" "$(grep -a -c "$s" "$OBJ" 2>/dev/null)" "$(grep -a -c "$s" "$K" 2>/dev/null)"
done
echo
echo "=== are the new frequencies visible as immediates in the object? ==="
python3 - <<'PY'
import struct
p="/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/annibale_adreno.o"
d=open(p,"rb").read()
for name,val in (("315000",315000),("379000",379000),("443000",443000),("491000",491000),
                 ("540000",540000),("608000",608000),("676000",676000),("738000",738000),
                 ("778000",778000),("840000",840000)):
    n=d.count(struct.pack("<I",val))
    print("  %-7s 0x%08x  little-endian occurrences: %d"%(name,val,n))
PY
echo
echo "=== annibale_gpu symbol still there ==="
llvm-nm "$NU" 2>/dev/null | grep -E "_annibale_gpu_submit|_annibale_gpu_irqs|_step_core_power" | head -5
