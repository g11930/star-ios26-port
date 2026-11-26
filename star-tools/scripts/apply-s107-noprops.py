import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
shutil.copyfile(P, P + ".s107-pre.bak")
src = open(P).read()

old = '''		/* s95: unconditional plugin properties so IOAcceleratorES is discoverable
		 * by Metal even with metal=0 (the two keys were missing -> device=0). */
		accelerator->setProperty(kAcceleratorPluginNameKey, "AnnibaleMetal");
		accelerator->setProperty(kAcceleratorPluginClassNameKey, "AnnibaleMetalDevice");
'''
new = '''		/* s107: publish the accelerator with NO plugin properties at all, so Metal
		 * cannot name a driver here and CoreAnimation must fall back to its software
		 * renderer instead of waiting on a Metal device that never appears. The two
		 * setProperty() calls are deliberately gone; the readback below now proves it. */
'''
if old not in src:
    print("ANCHOR FAIL"); sys.exit(1)
src = src.replace(old, new, 1)
open(P, "w").write(src)
print("PATCHED")
