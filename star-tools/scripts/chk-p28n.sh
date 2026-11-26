#!/bin/bash
B=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
python3 - <<'EOF'
for p in ("/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o",
          "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_exit.o",
          "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"):
    d = open(p, "rb").read()
    print(p.rsplit("/",1)[-1], "size", len(d),
          "| P28", d.count(b"P28"), "| xstat", d.count(b"xstat"), "| pid %d addr", d.count(b"pid %d addr"))
EOF
echo "--- object mtimes ---"
ls -la --time-style=full-iso "$B/osfmk/RELEASE/sleh.o" "$B/bsd/RELEASE/kern_exit.o"
echo "--- printf macro? ---"
grep -rn "define printf" /root/star26/kbuild/xnu-12377.121.6/pexpert/pexpert/pexpert.h /root/star26/kbuild/xnu-12377.121.6/pexpert/pexpert/protos.h
