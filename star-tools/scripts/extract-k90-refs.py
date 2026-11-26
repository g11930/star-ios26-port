#!/usr/bin/env python3
"""For each modified official file that mentions K90, dump the exact added/removed
lines that carry the reference, so we can decide whether it is a harmless include
or a real dependency on K90 drivers. Read-only."""
import re
import subprocess

TREE = "/root/star26/kbuild/xnu-12377.121.6"
OUT = "/mnt/c/ios26/k90-ref-lines.txt"
K90_RE = re.compile(
    r"annibale|adreno8|SM8750|sm8750|Mini(?:IO|Framebuffer|Apple|Drivers|Surface)"
    r"|Annibale|0xfc800000|DPU 12|FLIP_",
    re.I,
)


def git(*args):
    return subprocess.run(["git"] + list(args), cwd=TREE, capture_output=True, text=True).stdout


mods = [ln[3:] for ln in git("status", "--porcelain").splitlines() if ln.startswith(" M")]
with open(OUT, "w") as fh:
    for f in mods:
        d = git("diff", "--", f)
        hits = [x for x in d.splitlines()
                if x.startswith(("+", "-")) and not x.startswith(("+++", "---"))
                and K90_RE.search(x)]
        if not hits:
            continue
        fh.write("\n########## %s (%d hit lines) ##########\n" % (f, len(hits)))
        for x in hits:
            fh.write(x + "\n")
print("written", OUT)
