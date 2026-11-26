#!/usr/bin/env python3
import os, re, sys
ROOT = "/root/star26/s41/work/root"
path = sys.argv[1] if len(sys.argv) > 1 else ROOT + "/lib/libannibale.dylib"
data = open(path, "rb").read()
ss = [m.group().decode("ascii", "replace")
      for m in re.finditer(rb"[\x20-\x7e]{4,}", data)]
for i, s in enumerate(ss):
    print("%4d| %s" % (i, s[:200]))
