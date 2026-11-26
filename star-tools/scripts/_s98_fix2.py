#!/usr/bin/env python3
p = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
s = open(p).read()
marker = '\t\t{\n\t\tIOLog("IOAcceleratorES: kernel-side lookup'
assert s.count(marker) == 1
good = ('\t\t{\n'
        '\t\t\tOSDictionary * match = IOService::serviceMatching(\n'
        '\t\t\t    "IOAcceleratorES");\n'
        '\t\t\tIOService * found = match ?\n'
        '\t\t\t    IOService::copyMatchingService(match) : NULL;\n'
        '\t\t\tif (match) {\n'
        '\t\t\t\tmatch->release();\n'
        '\t\t\t}\n'
        '\t\t\tIOLog("IOAcceleratorES: kernel-side lookup = %s\\n",\n'
        '\t\t\t    found ? "FOUND" : "EMPTY");\n')
s = s.replace(marker, good)
open(p, "wb").write(s.encode())
print("repair ok")
