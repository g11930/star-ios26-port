#!/usr/bin/env python3
"""s89 (fixed): use the IORegistryEntry/OSObject member forms available in
this inc's scope: IOService::serviceMatching + IOService::copyMatchingService
(OSObject members), and metaClass name via getMetaClass()->getClassName()."""
import os
import shutil
import sys

K = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
CHECK = "--check" in sys.argv

OLD = '''		accelerator->registerService();
		IOLog("IOAcceleratorES: published metal=%u metal_native=%u\\n",
		    metal, metal_native);
		{
			/* s89: kernel-side self-test of the matching dict */
			IOService * found = copyMatchingService(
			    IOServiceMatching("IOAcceleratorES"));
			IOLog("IOAcceleratorES: kernel-side lookup = %s\\n",
			    found ? "FOUND" : "EMPTY");
			if (found) {
				IOLog("IOAcceleratorES: found name=%s class=%s\\n",
				    found->getName(),
				    found->metaGetClassName());
				found->release();
			}
		}'''
NEW = '''		accelerator->registerService();
		IOLog("IOAcceleratorES: published metal=%u metal_native=%u\\n",
		    metal, metal_native);
		{
			/* s89: kernel-side self-test of the matching dict */
			OSDictionary * match = IOService::serviceMatching(
			    "IOAcceleratorES");
			IOService * found = match ?
			    IOService::copyMatchingService(match) : NULL;
			if (match) {
				match->release();
			}
			IOLog("IOAcceleratorES: kernel-side lookup = %s\\n",
			    found ? "FOUND" : "EMPTY");
			if (found) {
				IOLog("IOAcceleratorES: found name=%s\\n",
				    found->getName());
				found->release();
			}
		}'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "IOService::serviceMatching" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s89.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] MiniFramebufferUserClient.inc")


if __name__ == "__main__":
    main()
