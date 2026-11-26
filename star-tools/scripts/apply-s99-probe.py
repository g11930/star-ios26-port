import re, shutil, sys

P = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
shutil.copyfile(P, P + ".s99-pre.bak")

src = open(P).read()

anchor_start = "\t\taccelerator->registerService();"
anchor_end = "\t} else {\n\t\tIOLog(\"IOAcceleratorES: publish FAILED"

i = src.find(anchor_start)
j = src.find(anchor_end)
if i < 0 or j < 0 or j <= i:
    print("ANCHOR FAIL", i, j); sys.exit(1)

new_body = '''\t\taccelerator->registerService();
\t\t{
\t\t\tOSString * pn = OSDynamicCast(OSString,
\t\t\t    accelerator->getProperty(kAcceleratorPluginNameKey));
\t\t\tOSString * pc = OSDynamicCast(OSString,
\t\t\t    accelerator->getProperty(kAcceleratorPluginClassNameKey));
\t\t\tIOLog("IOAcceleratorES: props after register: " kAcceleratorPluginNameKey "=%s "
\t\t\t    kAcceleratorPluginClassNameKey "=%s\\n",
\t\t\t    pn ? pn->getCStringNoCopy() : "(MISSING)",
\t\t\t    pc ? pc->getCStringNoCopy() : "(MISSING)");
\t\t}
\t\tIOLog("IOAcceleratorES: published metal=%u metal_native=%u "
\t\t    "entryID=0x%llx name=%s\\n",
\t\t    metal, metal_native,
\t\t    (unsigned long long)accelerator->getRegistryEntryID(),
\t\t    accelerator->getName());
\t\t{
\t\t\tstatic const char * const probe[] = {
\t\t\t    "AppleARMBacklight", "IOMobileFramebuffer",
\t\t\t    "IOAccelerator", "IOAcceleratorES"
\t\t\t};
\t\t\tfor (unsigned k = 0; k < 4; k++) {
\t\t\t\tOSDictionary * m = IOService::serviceMatching(probe[k]);
\t\t\t\tIOService * f = m ? IOService::copyMatchingService(m) : NULL;
\t\t\t\tIOLog("IOSvcProbe: match %s -> %s", probe[k],
\t\t\t\t    f ? "FOUND" : "EMPTY");
\t\t\t\tif (f != NULL) {
\t\t\t\t    IOLog(" (%s)", f->getName());
\t\t\t\t    f->release();
\t\t\t\t}
\t\t\t\tIOLog("\\n");
\t\t\t\tif (m != NULL) {
\t\t\t\t    m->release();
\t\t\t\t}
\t\t\t}
\t\t}
'''

src2 = src[:i] + new_body + src[j:]
open(P, "w").write(src2)
print("PATCHED", len(src), "->", len(src2))
