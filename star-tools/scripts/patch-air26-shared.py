#!/usr/bin/env python3
"""P26 #2: keep PIPE_BIND_SHARED off the software backend at source level.

P24 fixed this with a 4-byte binary patch (the `csel` that sets the bit).  Now
that the library is being rebuilt, the same fix belongs in the source: softpipe
routes any resource carrying PIPE_BIND_SHARED to softpipe_displaytarget_layout,
which asks the winsys for a display target, and the null winsys upstream returns
NULL unconditionally -- so every buffer of a page or more failed to allocate.
The bit is only needed so freedreno can lay a texture over a buffer by handle;
on softpipe the mirror path (buffer_set_mirror) does the same work in the
processor.
"""
import sys

SRC = "/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/compiler/air/air_metal.c"

OLD = "PIPE_BIND_INDEX_BUFFER | (size >= 4096 ? PIPE_BIND_SHARED : 0),"
NEW = ("PIPE_BIND_INDEX_BUFFER |\n"
       "                                    (size >= 4096 && !device->software\n"
       "                                     ? PIPE_BIND_SHARED : 0),")

body = open(SRC, encoding="utf-8").read()
if "size >= 4096 && !device->software" in body:
    print("already patched")
    sys.exit(0)
if body.count(OLD) != 1:
    print("FAIL: anchor count %d" % body.count(OLD))
    sys.exit(1)
body = body.replace(OLD, NEW)
open(SRC, "w", encoding="utf-8").write(body)
print("patched", SRC)
