#!/usr/bin/env python3
"""
s90: delayed self-tests -- if the async matching completes later, the
delayed lookups will find the service; if all three fail, the
registration itself never produced a matchable entry.
"""
import os
import shutil
import sys

K = "/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc"
CHECK = "--check" in sys.argv

OLD = '''		{
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
NEW = '''		{
			/* s90: self-tests at 0/+2s/+10s -- IOKit matching is
			 * asynchronous; if it completes later the delayed
			 * lookups will find the service. */
			for (unsigned attempt = 0; attempt < 3; attempt++) {
				if (attempt) {
					IOSleep(attempt == 1 ? 2000 : 8000);
				}
				OSDictionary * match = IOService::serviceMatching(
				    "IOAcceleratorES");
				IOService * found = match ?
				    IOService::copyMatchingService(match) : NULL;
				if (match) {
					match->release();
				}
				IOLog("IOAcceleratorES: self-test %u = %s\\n",
				    attempt, found ? "FOUND" : "EMPTY");
				if (found) {
					IOLog("IOAcceleratorES: found name=%s\\n",
					    found->getName());
					found->release();
					break;
				}
			}
		}'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "self-test %u" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s90.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] MiniFramebufferUserClient.inc")


if __name__ == "__main__":
    main()
