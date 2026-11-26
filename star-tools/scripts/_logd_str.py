#!/usr/bin/env python3
data = open("/root/dsc26/dyld/usr/libexec/logd", "rb").read()
for off in (0x2AC47, 0x2AC30, 0x2AC00, 0x2AC60, 0x2AC80, 0x2AC20):
    e = data.find(b"\0", off)
    print(hex(off), repr(data[off:e][:140].decode("utf-8", "replace")))
