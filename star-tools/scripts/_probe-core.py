#!/usr/bin/env python3
import os, re
ROOT = "/root/star26/s41/work/root"
def strings(path, minlen=4):
    data = open(path, "rb").read()
    return [m.group().decode("ascii", "replace")
            for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, data)]

print("==== annibale-core ====")
ss2 = strings(ROOT + "/lib/libannibale.dylib")
print("size=%d nstrings=%d" % (os.path.getsize(ROOT + "/lib/libannibale.dylib"), len(ss2)))
want2 = re.compile(r"caenv|ca_vbl|CoreAnimation|COREANIMATION|metal|renderer|softpipe|opengl|gles|ca_", re.I)
seen2 = set()
for s in ss2:
    if want2.search(s) and s not in seen2:
        seen2.add(s)
        print("   ", s[:170])
print("   count=%d" % len(seen2))
