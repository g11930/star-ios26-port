#!/bin/bash
B=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
echo "now: $(date)"
echo "--- sleh.d first line(s) ---"
head -3 "$B/osfmk/RELEASE/sleh.d"
echo "--- object mtime ---"
ls -la --time-style=full-iso "$B/osfmk/RELEASE/sleh.o" "$B/bsd/RELEASE/kern_exit.o"
echo "--- CC lines ---"
grep -n "CC " /root/star26/p28-build.log | tail -10
echo "--- errors/warnings mentioning sleh ---"
grep -n "sleh" /root/star26/p28-build.log | head -10
echo "--- python probe check on object ---"
python3 - <<'EOF'
for p in ("/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o",
          "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_exit.o"):
    d = open(p, "rb").read()
    print(p.rsplit("/",1)[-1], "P28FAULT", d.count(b"P28FAULT"), "P28EXIT", d.count(b"P28EXIT"),
          "pid %d addr", d.count(b"pid %d addr"), "size", len(d))
EOF
