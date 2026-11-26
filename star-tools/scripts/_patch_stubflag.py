import re

# 1) a way for the real driver to end the stub state
p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

if "AnnibaleGPUStartReal" not in s:
    anchor = """/*
 * Register the service with no GPU behind it. Called once, early, from bsd_init on a platform
 * whose GPU is not the one adreno8 drives; the ordinary start keeps that platform's own path.
 * Registration only: no register is read, no firmware is loaded, no buffer is made.
 */"""
    new_fn = """/*
 * The GPU itself has now been started (annibale_adreno.c, "THE GPU STAYS ON"): the service the
 * stub registered early is the real one from here on.  Everything the user client answers is
 * keyed off gGPUStub, and while it stays true every request -- GET_PARAM included -- is refused
 * as "there is no GPU here", which is exactly what freedreno sees when it tries to make a screen.
 */
bool
AnnibaleGPUStartReal(void)
{
	if (gGPUService != NULL) {
		gGPUStub = false;       /* the early stub service becomes the real one */
		return true;
	}
	gGPUStub = false;
	return AnnibaleGPUStart();
}

""" + anchor
    assert anchor in s
    s = s.replace(anchor, new_fn, 1)

if "bool AnnibaleGPUStartReal(void);" not in s:
    s = s.replace("bool AnnibaleGPUStartStub(void);",
                  "bool AnnibaleGPUStartStub(void);\nbool AnnibaleGPUStartReal(void);", 1)

open(p, "w").write(s)
print("AnnibaleGPUStartReal added")

# 2) the driver uses it instead of AnnibaleGPUStart()
q = "/root/star26/star-native/bsd/dev/star/annibale_adreno.c"
t = open(q).read()
if "AnnibaleGPUStartReal" not in t:
    t = t.replace("extern void AnnibaleGPUStart(void);", "extern void AnnibaleGPUStart(void);\nextern bool AnnibaleGPUStartReal(void);", 1)
    t = t.replace("\t\t\tAnnibaleGPUStart();", "\t\t\tAnnibaleGPUStartReal();", 1)
    open(q, "w").write(t)
    print("driver now calls AnnibaleGPUStartReal")
else:
    print("driver already patched")
