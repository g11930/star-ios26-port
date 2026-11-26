#!/usr/bin/env python3
"""Dump full diffs / contents of the files that decide what star-native must carry."""
import os
import subprocess

TREE = "/root/star26/kbuild/xnu-12377.121.6"
OUT = "/mnt/c/ios26/critical-diffs.txt"
DIFF_FILES = [
    "bsd/kern/bsd_init.c",
    "osfmk/arm64/machine_routines.c",
    "osfmk/arm/cpuid.c",
    "makedefs/MakeInc.def",
    "osfmk/conf/files",
    "osfmk/conf/files.arm64",
    "iokit/conf/files",
    "libkern/conf/files",
    "config/MASTER",
]
CONTENT_FILES = [
    "config/MASTER.arm64.bcm2837",
    "pexpert/pexpert/arm64/BCM2837.h",
    "osfmk/kern/annibale_threads.c",
    "iokit/Kernel/GenericARMPE.cpp",
]


def git(*args):
    return subprocess.run(["git"] + list(args), cwd=TREE, capture_output=True, text=True).stdout


with open(OUT, "w") as fh:
    for f in DIFF_FILES:
        fh.write("\n########## DIFF %s ##########\n" % f)
        fh.write(git("diff", "--", f))
    for f in CONTENT_FILES:
        p = os.path.join(TREE, f)
        fh.write("\n########## CONTENT (untracked) %s ##########\n" % f)
        if os.path.exists(p):
            txt = open(p, errors="replace").read()
            fh.write(txt[:16000])
            if len(txt) > 16000:
                fh.write("\n...[truncated at 16000 chars, total %d]...\n" % len(txt))
        else:
            fh.write("(missing)\n")
print("written", OUT, os.path.getsize(OUT))
