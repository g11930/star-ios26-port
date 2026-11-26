#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage20 -- remove the arm64e-era pthread_start() stub from loader_return.c.

s24 (after oslog was disabled) reached IOKit, registered all 4 CPUs, started
MiniIOMobileFramebuffer and AnnibaleGPU, then panicked:

    PANIC caller 0xfffffff0075e91b8: pthread kernel extension not loaded
    (function table is NULL). @pthread_shims.c:319

Both trees link -lpthread_kext (see mach.release.bcm2837.linkarchives).  The
SDK archive libpthread_kext.a:pthread_kern_init.o defines the real
pthread_start(), which calls pthread_kext_register() to install the function
table.  Our loader_return.c defines a local `void pthread_start(void) {}` stub
(added during the discarded arm64e experiment).  Static archive extraction
only pulls members that resolve currently-undefined symbols, so the stub
shadows the real one: pthread_kern_init.o is never linked, pthread_functions
stays NULL, and pthread_init() panics.

Fix: delete that stub.  Keep the __firehose_* stubs and the oslog disable from
stage19 (already verified working) -- one variable at a time.

Idempotent; --check read-only.
"""
import io
import sys

P = "/root/star26/star-native/osfmk/arm64/loader_return.c"

STUB = '''
void pthread_start(void);
void pthread_start(void)
{
}
'''


def main():
    s = io.open(P, encoding="utf-8", errors="surrogateescape").read()
    if "--check" in sys.argv:
        ok = "void pthread_start(void)" not in s
        print("CHECK", "PASS" if ok else "FAIL (stub still present)")
        return 0 if ok else 1
    if "void pthread_start(void)" not in s:
        print("already removed")
        return 0
    n = s.count(STUB)
    if n != 1:
        print("FAIL: stub block found %d times" % n)
        return 1
    s = s.replace(STUB, "\n", 1)
    io.open(P, "w", encoding="utf-8", errors="surrogateescape").write(s)
    print("loader_return.c: pthread_start() stub removed; libpthread_kext.a can now link")
    return 0


if __name__ == "__main__":
    sys.exit(main())
