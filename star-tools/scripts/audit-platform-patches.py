#!/usr/bin/env python3
"""Read-only audit of the K90 kbuild tree.

Classify every change relative to the official xnu-12377.121.6 baseline into:
  * Linux/WSL toolchain fixups (must be carried to star-native)
  * platform-independent runtime patches (must be carried)
  * K90-specific drivers / references (must NOT be carried)

No file is written inside the source trees. Two reports go to /mnt/c/ios26/.
"""
import os
import re
import subprocess

TREE = "/root/star26/kbuild/xnu-12377.121.6"
OUT = "/mnt/c/ios26"

K90_RE = re.compile(
    r"annibale|adreno8|SM8750|sm8750|Mini(?:IO|Framebuffer|Apple|Drivers|Surface)"
    r"|Annibale|0xfc800000|DPU 12|dpu 12|qcom,mdss_dsi|splash_region|FLIP_",
    re.I,
)
CONF_FILES = [
    "Makefile",
    "SETUP/config/doconf",
    "bsd/conf/Makefile.arm64",
    "bsd/conf/files",
    "config/MASTER",
    "iokit/conf/files",
    "libkern/conf/files",
    "makedefs/MakeInc.cmd",
    "makedefs/MakeInc.def",
    "makedefs/MakeInc.top",
    "osfmk/conf/files",
    "osfmk/conf/files.arm64",
    "pexpert/pexpert/arm64/Makefile",
]


def git(*args):
    return subprocess.run(
        ["git"] + list(args), cwd=TREE, capture_output=True, text=True
    ).stdout


status = git("status", "--porcelain").splitlines()
mods = [ln[3:] for ln in status if ln.startswith(" M")]
untracked = [ln[3:] for ln in status if ln.startswith("??")]
# untracked files reported by git as plain paths (directories end with /)

report = []
for f in mods:
    d = git("diff", "--", f)
    add = sum(1 for x in d.splitlines() if x.startswith("+") and not x.startswith("+++"))
    dele = sum(1 for x in d.splitlines() if x.startswith("-") and not x.startswith("---"))
    hits = sorted({m.group(0) for m in K90_RE.finditer(d)}, key=str.lower)
    report.append((f, add, dele, hits))

with open(os.path.join(OUT, "platform-patch-audit.txt"), "w") as fh:
    fh.write("BASELINE %s\n" % git("log", "--oneline", "-1").strip())
    fh.write("modified=%d untracked=%d\n\n" % (len(mods), len(untracked)))
    fh.write("=== MODIFIED OFFICIAL FILES (file | +lines | -lines | K90 hits) ===\n")
    for f, a, d, hits in report:
        fh.write("%-52s %5d %5d  %s\n" % (f, a, d, ",".join(hits) if hits else "-"))
    fh.write("\n=== MODIFIED WITH K90 REFERENCES ===\n")
    for f, a, d, hits in report:
        if hits:
            fh.write("%s : %s\n" % (f, ",".join(hits)))
    fh.write("\n=== UNTRACKED (top-level entries) ===\n")
    for f in untracked:
        fh.write("%s\n" % f)

with open(os.path.join(OUT, "conf-diffs.txt"), "w") as fh:
    for f in CONF_FILES:
        fh.write("\n########## %s ##########\n" % f)
        fh.write(git("diff", "--", f))

# also dump untracked config files that exist and may reference K90 drivers
for extra in ["config/MASTER.arm64.bcm2837", "pexpert/pexpert/arm64/BCM2837.h"]:
    p = os.path.join(TREE, extra)
    if os.path.exists(p):
        with open(os.path.join(OUT, "extra-config-diffs.txt"), "a") as fh:
            fh.write("\n########## %s (UNTRACKED, full) ##########\n" % extra)
            fh.write(open(p, errors="replace").read()[:40000])

print("modified=%d untracked=%d" % (len(mods), len(untracked)))
print("modified-with-K90-refs=%d" % sum(1 for r in report if r[3]))
for f, a, d, hits in report:
    if hits:
        print("  K90REF %-48s %s" % (f, ",".join(hits[:3])))
print("report: /mnt/c/ios26/platform-patch-audit.txt")
print("conf diffs: /mnt/c/ios26/conf-diffs.txt")
