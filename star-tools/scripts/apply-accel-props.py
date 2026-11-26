#!/usr/bin/env python3
"""
s91: publish the IOAcceleratorES service with the plugin properties
UNCONDITIONALLY.  K90 (metal=1) sets kAcceleratorPluginNameKey=
"AnnibaleMetal" + kAcceleratorPluginClassNameKey="AnnibaleMetalDevice";
without them the service is invisible to the userspace IOKit matching
(the kernel-side copyMatchingService finds it, the userland lookup does
not -- s88/s89/s90).  The AnnibaleMetal plugin is exactly the softpipe/
stub path, so setting it with metal=0 is correct.
Read-only, idempotent, backup, strict anchors.
"""
import os
import shutil
import sys

K = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
CHECK = "--check" in sys.argv

OLD = '''		accelerator->setName("sgx");
		if (gAcceleratorTakesProperties && metal_native != 0) {
			accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
			accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
		}
		accelerator->registerService();'''
NEW = '''		accelerator->setName("sgx");
		/* s91: unconditional -- without the plugin properties the service
		 * is invisible to the userspace IOKit matching (the kernel-side
		 * copyMatchingService found it, the SB/bbd lookup did not).
		 * AnnibaleMetal IS the softpipe/stub driver, so this is correct
		 * with metal=0 as well. */
		accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
		accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
		accelerator->registerService();'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "s91: unconditional" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s91.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] MiniFramebufferUserClient.inc")


if __name__ == "__main__":
    main()
