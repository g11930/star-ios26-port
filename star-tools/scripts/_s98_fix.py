#!/usr/bin/env python3
p = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
s = open(p).read()
start = s.index("\t\tbool reg = accelerator->registerService();")
end = s.index("\t\tIOLog(\"IOAcceleratorES: kernel-side lookup")
new = ("\t\taccelerator->registerService();\n"
       "\t\tIOLog(\"IOAcceleratorES: published metal=%u metal_native=%u \"\n"
       "\t\t    \"entryID=0x%llx name=%s\\n\",\n"
       "\t\t    metal, metal_native,\n"
       "\t\t    (unsigned long long)accelerator->getRegistryEntryID(),\n"
       "\t\t    accelerator->getName());\n"
       "\t\t{\n")
s = s[:start] + new + s[end:]
open(p, "wb").write(s.encode())
print("patched ok")
