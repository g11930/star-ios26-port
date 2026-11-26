#!/usr/bin/env python3
"""P21: register AnnibaleGPU with no GPU behind it, so drawables fall back to process memory.

Three files, two trees. Every anchor is asserted unique before anything is written.
"""
import sys, hashlib

K = "/root/star26/kbuild/xnu-12377.121.6"          # the tree that is compiled
W = "/root/star26/hackios-xnu-kernel/xnu/files"    # the tree that is read / shipped

FILES = [
    (K + "/iokit/Kernel/AnnibaleGPU.cpp", W + "/iokit/Kernel/AnnibaleGPU.cpp"),
    (K + "/bsd/dev/annibale/annibale_gpu_dispatch.c", W + "/bsd/dev/annibale/annibale_gpu_dispatch.c"),
    (K + "/bsd/kern/bsd_init.c", None),
]


def read(p):
    with open(p, "r", encoding="utf-8", errors="surrogateescape") as f:
        return f.read()


def write(p, s):
    with open(p, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.write(s)


def sub(text, old, new, where):
    n = text.count(old)
    if n != 1:
        sys.exit("anchor appears %d times in %s: %r" % (n, where, old[:70]))
    return text.replace(old, new, 1)


# ---------------------------------------------------------------- AnnibaleGPU.cpp
STUB_GLOBALS = '''/*
 * star: the service without a GPU behind it.
 *
 * The drawable driver asks this service one question -- describe this IOSurface -- and what it
 * needs is an answer, not a GPU: kIOReturnUnsupported tells it the surface wraps memory of the
 * process's own, which is true here, and it then draws through the software rasteriser. With no
 * service at all there is nobody to ask, every drawable is nil, and the window server composites
 * nothing. So on a port whose GPU has no driver yet the service is still registered, and every
 * request to it is refused in the one way that means "not me" -- never in a way that pretends a
 * buffer exists.
 */
static bool gGPUStub;

bool
AnnibaleGPUIsStub(void)
{
	return gGPUStub;
}

static AnnibaleGPU * gGPUService;
'''

ANCHOR_GLOBALS = "static AnnibaleGPU * gGPUService;\n"

ANCHOR_REGISTER = '''	gGPUService = gpu; /* Keep the actual registered service for repeated start checks. */
	return true;
}
'''

STUB_START_FN = '''
/*
 * Register the service with no GPU behind it. Called once, early, from bsd_init on a platform
 * whose GPU is not the one adreno8 drives; the ordinary start keeps that platform's own path.
 * Registration only: no register is read, no firmware is loaded, no buffer is made.
 */
bool
AnnibaleGPUStartStub(void)
{
	gGPUStub = true;
	if (!AnnibaleGPUStart()) {
		IOLog("AnnibaleGPU: the stub service did not register; drawables stay nil\\n");
		return false;
	}
	IOLog("AnnibaleGPU: stub service registered; a surface is the process's own memory\\n");
	return true;
}
'''

ANCHOR_UC = '''	bool available = !gGPUReported && annibale_gpu_ready();
	IOLockUnlock(gGPULock);
	if (!available || !IOUserClient::start(provider)) {
'''
NEW_UC = '''	bool available = gGPUStub || (!gGPUReported && annibale_gpu_ready());
	IOLockUnlock(gGPULock);
	if (!available || !IOUserClient::start(provider)) {
'''

ANCHOR_EM = '''	if (args->structureInput == NULL || size > sizeof(r) || fBuffers == NULL) {
		return kIOReturnBadArgument;
	}
'''
NEW_EM = '''	if (gGPUStub) {
		/*
		 * kAnnibaleSurface's kIOReturnUnsupported is the answer that matters: annibaledrawable
		 * reads it as "this surface is memory of your own" and draws through softpipe instead of
		 * taking a GPU buffer. Everything else is refused the same way rather than answered,
		 * because there is no GPU here to answer with and a plausible number would be worse than
		 * a refusal. No buffer table is touched and no register is read.
		 */
		return kIOReturnUnsupported;
	}
	if (args->structureInput == NULL || size > sizeof(r) || fBuffers == NULL) {
		return kIOReturnBadArgument;
	}
'''

# ------------------------------------------------------ annibale_gpu_dispatch.c
ANCHOR_DISPATCH = "extern bool AnnibaleGPUStart(void);\n"
NEW_DISPATCH = '''extern bool AnnibaleGPUStart(void);
extern bool AnnibaleGPUStartStub(void);

/*
 * star: the AnnibaleGPU service with nothing behind it, for a port whose GPU adreno8 does not
 * drive. Registration only -- no register, no firmware, no buffer. Not on the annibale platform,
 * where the real service is the one userland wants, and not when it has been done already.
 */
bool
annibale_gpu_stub_start(void)
{
	static bool tried;

	if (tried || annibale_platform_is_annibale()) {
		return false;
	}
	tried = true;
	return AnnibaleGPUStartStub();
}
'''

# ------------------------------------------------------------------- bsd_init.c
ANCHOR_DECL = "#include <sys/annibale_apfs_check.h>\n"
NEW_DECL = '''#include <sys/annibale_apfs_check.h>

/* star26: an AnnibaleGPU service with no GPU behind it, so a drawable is the caller's memory */
extern bool annibale_gpu_stub_start(void);
'''

ANCHOR_CALL = """		annibale_sparse_init();          /* /dev/rsp0, part of an image too big to hold */
"""
NEW_CALL = """		annibale_sparse_init();          /* /dev/rsp0, part of an image too big to hold */
		/*
		 * After the providers above, before anything asks for a drawable. On a port whose GPU has
		 * no driver this is what turns "every drawable is nil" into "every drawable is memory of
		 * the caller's own", and it does nothing on the annibale platform.
		 */
		annibale_gpu_stub_start();
"""


def patch_gpu(text):
    text = sub(text, ANCHOR_GLOBALS, STUB_GLOBALS, "AnnibaleGPU.cpp globals")
    text = sub(text, ANCHOR_REGISTER, ANCHOR_REGISTER + STUB_START_FN, "AnnibaleGPU.cpp register")
    text = sub(text, ANCHOR_UC, NEW_UC, "AnnibaleGPU.cpp user client start")
    text = sub(text, ANCHOR_EM, NEW_EM, "AnnibaleGPU.cpp externalMethod")
    return text


for kpath, wpath in FILES:
    text = read(kpath)
    marker = "gGPUStub" if kpath.endswith("AnnibaleGPU.cpp") else "annibale_gpu_stub_start"
    if marker in text:
        print("already patched: " + kpath)
        continue

    if kpath.endswith("AnnibaleGPU.cpp"):
        text = patch_gpu(text)
    elif kpath.endswith("annibale_gpu_dispatch.c"):
        text = sub(text, ANCHOR_DISPATCH, NEW_DISPATCH, kpath)
    else:
        text = sub(text, ANCHOR_DECL, NEW_DECL, kpath)
        text = sub(text, ANCHOR_CALL, NEW_CALL, kpath)

    write(kpath, text)
    print("patched: %s  sha256=%s" % (kpath, hashlib.sha256(text.encode()).hexdigest()[:16]))
    if wpath:
        write(wpath, text)
        print("mirrored: %s" % wpath)
