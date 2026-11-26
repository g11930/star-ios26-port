#!/usr/bin/env python3
data = open("/root/dsc26/dyld/usr/libexec/logd", "rb").read()
for off in (0x2AB94, 0x2AB80, 0x2AB60, 0x2ABA0, 0x2ABB0):
    e = data.find(b"\0", off)
    print(hex(off), repr(data[off:e][:150].decode("utf-8", "replace")))
