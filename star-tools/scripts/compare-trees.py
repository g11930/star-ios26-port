#!/usr/bin/env python3
"""Read-only: compare the assembled K90 tree with the already-linked feasibility
tree, restricted to files the feasibility tree modified locally.

IDENTICAL -> K90 patch series already carries the Linux/board fix.
DIFFERENT -> K90 has its own (possibly equivalent) version, needs a look.
MISSING   -> file absent in the assembled tree.
"""
import os
import subprocess

FEAS = "/root/xnu26-test/xnu-12377.121.6"
KB = "/root/star26/kbuild/xnu-12377.121.6"

files = subprocess.check_output(
    ["git", "-C", FEAS, "diff", "--name-only"], text=True).splitlines()

same, diff, missing = [], [], []
for rel in files:
    a, b = os.path.join(FEAS, rel), os.path.join(KB, rel)
    if not os.path.isfile(b):
        missing.append(rel)
    elif open(a, "rb").read() == open(b, "rb").read():
        same.append(rel)
    else:
        diff.append(rel)

print("files checked:", len(files))
print("IDENTICAL (%d):" % len(same))
for f in same:
    print("   =", f)
print("DIFFERENT (%d):" % len(diff))
for f in diff:
    print("   ~", f)
print("MISSING (%d):" % len(missing))
for f in missing:
    print("   -", f)
