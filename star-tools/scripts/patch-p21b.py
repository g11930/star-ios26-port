#!/usr/bin/env python3
"""P21b: put AnnibaleGPUStartStub in the extern "C" block, so annibale_gpu_dispatch.c can call it.

Without the declaration there, the definition gets C++ linkage (__Z21AnnibaleGPUStartStubv) and the
C caller asks for _AnnibaleGPUStartStub, which is the undefined symbol the link failed on.
"""
import sys

K = "/root/star26/kbuild/xnu-12377.121.6/iokit/Kernel/AnnibaleGPU.cpp"
W = "/root/star26/hackios-xnu-kernel/xnu/files/iokit/Kernel/AnnibaleGPU.cpp"

OLD = """bool AnnibaleGPUStart(void);
void AnnibaleGPUStop(void);
"""
NEW = """bool AnnibaleGPUStart(void);
bool AnnibaleGPUStartStub(void);
bool AnnibaleGPUIsStub(void);
void AnnibaleGPUStop(void);
"""

for path in (K, W):
    with open(path, "r", encoding="utf-8", errors="surrogateescape") as f:
        text = f.read()
    if "bool AnnibaleGPUStartStub(void);" in text:
        print("already declared: " + path)
        continue
    if text.count(OLD) != 1:
        sys.exit("anchor appears %d times in %s" % (text.count(OLD), path))
    text = text.replace(OLD, NEW, 1)
    with open(path, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.write(text)
    print("declared: " + path)
