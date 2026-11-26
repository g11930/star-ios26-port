#!/usr/bin/env python3
import sys, re

for tag, path in [
    ("NEW(s42)", "/root/star26/s42/work/root/lib/libannibaleair.dylib"),
    ("OLD(s41)", "/root/star26/s41/work/root/lib/libannibaleair.dylib"),
]:
    d = open(path, "rb").read()
    found = []
    for m in re.finditer(rb"softpipe half lowering[ -~]{0,70}", d):
        s = m.group(0).split(b"\x00")[0].decode("ascii", "replace")
        found.append((m.start(), s))
    print("== %s  (%d strings)" % (tag, len(found)))
    for off, s in found:
        print("   %#09x  %s" % (off, s))
    # also look for any 'tex op' near
    for m in re.finditer(rb"[ -~]{0,40}tex op %u[ -~]{0,30}", d):
        print("   TEX: %#09x %s" % (m.start(), m.group(0).decode("ascii", "replace")))
    print()
