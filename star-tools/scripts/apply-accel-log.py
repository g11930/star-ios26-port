#!/usr/bin/env python3
"""
s88: unconditional logging in publishAccelerator() to confirm whether the
IOAcceleratorES service is actually published (the s87 lookup from
SpringBoard/backboardd failed: "IOAcceleratorES unavailable").
Read-only, log-only, idempotent, backup, strict anchors.
"""
import os
import shutil
import sys

K = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
CHECK = "--check" in sys.argv

OLD = '''	if (accelerator != NULL && accelerator->init() && accelerator->attach(provider)) {
		accelerator->setName("sgx");
		if (gAcceleratorTakesProperties && metal_native != 0) {
			accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
			accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
		}
		accelerator->registerService();
		if (gAcceleratorTakesProperties) {
			IOLog("IOAcceleratorES: metal=%u metal_native=%u: service published\\n",
			    metal, metal_native);
		}
	}
	OSSafeReleaseNULL(accelerator);'''
NEW = '''	IOLog("IOAcceleratorES: publish begin alloc=%s\\n",
	    accelerator != NULL ? "ok" : "NULL");
	if (accelerator != NULL && accelerator->init() && accelerator->attach(provider)) {
		accelerator->setName("sgx");
		if (gAcceleratorTakesProperties && metal_native != 0) {
			accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
			accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
		}
		accelerator->registerService();
		IOLog("IOAcceleratorES: published metal=%u metal_native=%u\\n",
		    metal, metal_native);
	} else {
		IOLog("IOAcceleratorES: publish FAILED (init/attach)\\n");
	}
	OSSafeReleaseNULL(accelerator);'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "publish begin alloc" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s88.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] MiniFramebufferUserClient.inc")


if __name__ == "__main__":
    main()
