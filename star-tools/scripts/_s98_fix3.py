#!/usr/bin/env python3
p = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
s = open(p).read()
bad = ('\t\t\tIOLog("IOAcceleratorES: kernel-side lookup = %s\\n",\n'
       '\t\t\t    found ? "FOUND" : "EMPTY");\n'
       ' = %s\\n",\n'
       '\t\t\t    found ? "FOUND" : "EMPTY");\n')
good = ('\t\t\tIOLog("IOAcceleratorES: kernel-side lookup = %s\\n",\n'
        '\t\t\t    found ? "FOUND" : "EMPTY");\n')
assert s.count(bad) == 1, s.count(bad)
open(p, "wb").write(s.replace(bad, good).encode())
print("clean ok")
