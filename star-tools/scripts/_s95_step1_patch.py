#!/usr/bin/env python3
# s95 step1: remove the guard around the two Accelerator plugin properties.
# Single variable: only this guard changes; CS patch and everything else untouched.
import sys, os, shutil
K = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
s = open(K, encoding="utf-8").read()
old = """\t\taccelerator->setName("sgx");
\t\tif (gAcceleratorTakesProperties && metal_native != 0) {
\t\t\taccelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
\t\t\taccelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
\t\t}
\t\taccelerator->registerService();
"""
new = """\t\taccelerator->setName("sgx");
\t\t/* s95: unconditional plugin properties so IOAcceleratorES is discoverable
\t\t * by Metal even with metal=0 (the two keys were missing -> device=0). */
\t\taccelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
\t\taccelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
\t\taccelerator->registerService();
"""
if old not in s:
    print("FAIL: guard block not found (already patched or different)"); sys.exit(1)
s = s.replace(old, new, 1)
shutil.copy2(K, K + ".s94-pre-step1.bak")
open(K, "w", encoding="utf-8").write(s)
print("OK: guard removed; backup -> " + K + ".s94-pre-step1.bak")
