#!/bin/bash
echo "now: $(date)"
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
echo "--- find objects ---"
find "$K" -name "sleh.cpo" -o -name "kern_exit.cpo" | head
echo "--- strings in kernel ---"
python3 - <<'EOF'
p = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
d = open(p, "rb").read()
for k in (b"P28FAULT", b"P28EXIT", b"Undefined kernel instruction"):
    print(k, d.count(k))
print("size", len(d))
EOF
echo "--- the kernel mtime ---"
ls -la --time-style=full-iso "$K/mach.release.bcm2837"
echo "--- does sleh.c really have the probe ---"
grep -n "P28FAULT" /root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
echo "--- tail of build log ---"
tail -12 /root/star26/p28-build.log
