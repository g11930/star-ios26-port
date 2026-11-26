#!/usr/bin/env python3
import os, re

ROOT = "/root/star26/s41/work/root"

def strings(path, minlen=4):
    data = open(path, "rb").read()
    return [m.group().decode("ascii", "replace")
            for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, data)]

print("==== air: backend / env knobs ====")
ss = strings(ROOT + "/lib/libannibaleair.dylib")
want = re.compile(r"llvmpipe|LP_|ANNIBALE_|GALLIUM|softpipe|annibale_|ANNIBALE|half|fp16|lower", re.I)
seen = set()
for s in ss:
    if want.search(s) and s not in seen:
        seen.add(s)
        print("   ", s[:160])
print("   count=%d" % len(seen))

print("\n==== annibale-core: ca/metal knobs ====")
ss2 = strings(ROOT + "/lib/libannibale.dylib")
want2 = re.compile(r"caenv|ca_vbl|ca_|CoreAnimation|COREANIMATION|metal|renderer|softpipe|opengl|gles", re.I)
seen2 = set()
for s in ss2:
    if want2.search(s) and s not in seen2:
        seen2.add(s)
        print("   ", s[:160])
print("   count=%d" % len(seen2))
