import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
src = open(P).read()

old = '''		/* s107: publish the accelerator with NO plugin properties at all, so Metal
		 * cannot name a driver here and CoreAnimation must fall back to its software
		 * renderer instead of waiting on a Metal device that never appears. The two
		 * setProperty() calls are deliberately gone; the readback below now proves it. */
'''
new = '''		/* s110: restore the two plugin properties. s107 removed them and the injected
		 * Metal shim went from "registration completed device=1 / backend=softpipe" to
		 * "IOAcceleratorES unavailable / device=0" -- with no properties Metal cannot
		 * name the driver, so the whole registration aborts. */
		accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
		accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
'''
if old not in src:
    print("ANCHOR FAIL"); sys.exit(1)
src = src.replace(old, new, 1)
open(P, "w").write(src)
print("PATCHED")
