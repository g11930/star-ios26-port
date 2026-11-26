import shutil, sys

P1 = "/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp"
P2 = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
shutil.copyfile(P1, P1 + ".s105-pre.bak")
shutil.copyfile(P2, P2 + ".s105-pre.bak")

src = open(P1).read()

anchor = 'OSDefineMetaClassAndStructors(IOMobileFramebuffer, IOService);\n'
if anchor not in src:
    print("CLASS ANCHOR FAIL"); sys.exit(1)

classes = '''OSDefineMetaClassAndStructors(IOMobileFramebuffer, IOService);

/*
 * s105: backboardd matches this service by class name, and the names it knows are
 * "AppleH1CLCD" and then "AppleM2CLCD" (see the IOServiceMatching pair in /usr/libexec/
 * backboardd around 0x1000462e4). Publish the same driver under both, as a chain, so
 * either match succeeds; every cast in this file still lands on IOMobileFramebuffer.
 */
class AppleH1CLCD : public IOMobileFramebuffer
{
	OSDeclareDefaultStructors(AppleH1CLCD);
};

OSDefineMetaClassAndStructors(AppleH1CLCD, IOMobileFramebuffer);

class AppleM2CLCD : public AppleH1CLCD
{
	OSDeclareDefaultStructors(AppleM2CLCD);
};

OSDefineMetaClassAndStructors(AppleM2CLCD, AppleH1CLCD);

'''
src = src.replace(anchor, classes, 1)
open(P1, "w").write(src)

src2 = open(P2).read()
old = "\tIOMobileFramebuffer * fb = OSTypeAlloc(IOMobileFramebuffer);\n"
new = ("\t/* s105: published as AppleM2CLCD so backboardd's IOServiceMatching finds it */\n"
       "\tIOMobileFramebuffer * fb = OSTypeAlloc(AppleM2CLCD);\n")
if old not in src2:
    print("ALLOC ANCHOR FAIL"); sys.exit(1)
src2 = src2.replace(old, new, 1)
open(P2, "w").write(src2)
print("PATCHED")
