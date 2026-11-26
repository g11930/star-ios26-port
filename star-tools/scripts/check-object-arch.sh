#!/bin/bash
# Are the object files really arm64e now?  The linked kernel's subtype comes from
# the link flag, so only the objects tell the truth.
D=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
python3 - "$D" <<'PY'
import glob, struct, sys, os
D = sys.argv[1]
pats = ["bsd/RELEASE/kern_exec.o", "osfmk/RELEASE/loader_return.o",
        "osfmk/RELEASE/sleh.o", "osfmk/RELEASE/kalloc.o",
        "bsd/RELEASE/star_display_handoff.o"]
for rel in pats:
    p = os.path.join(D, rel)
    if not os.path.exists(p):
        cand = glob.glob(os.path.join(D, "**", os.path.basename(rel)), recursive=True)
        p = cand[0] if cand else None
    if not p:
        print("%-34s (missing)" % rel); continue
    d = open(p, "rb").read(32)
    m, ct, cs = struct.unpack_from("<Iii", d, 0)
    print("%-34s cpusubtype 0x%08x  %s" % (rel, cs & 0xffffffff,
          "arm64e" if (cs & 0xffffff) == 2 else "arm64"))
PY
