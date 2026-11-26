#!/usr/bin/env python3
# s97 diag: add a rate-limited IOLog inside miniamfi_vnode_check_signature.
# Pure observation, no behavior change. Tells us if the hook fires and what cs_flags it sees.
import sys, shutil
K = "/root/star26/star-native/bsd/kern/kern_minimac.c"
s = open(K, encoding="utf-8").read()
if "S97 hook" in s:
    print("FAIL: already instrumented"); sys.exit(1)

old = """\tif (star_cs_valid) {
\t\t*cs_flags |= CS_VALID;
\t}
\treturn 0;
"""
new = """\tif (star_cs_valid) {
\t\t*cs_flags |= CS_VALID;
\t}
\t{
\t\tstatic unsigned s97_n;
\t\tif (s97_n < 16) {
\t\t\ts97_n++;
\t\t\tIOLog("S97 hook pid=%d flags_in=0x%x out=0x%x valid=%d\\n",
\t\t\t    proc_getpid(current_proc()),
\t\t\t    (unsigned)(*cs_flags & ~CS_VALID), (unsigned)*cs_flags,
\t\t\t    (int)((*cs_flags & CS_VALID) != 0));
\t\t}
\t}
\treturn 0;
"""
if old not in s:
    print("FAIL: hook anchor missing"); sys.exit(1)
s = s.replace(old, new, 1)
shutil.copy2(K, K + ".s96-pre-diag.bak")
open(K, "w", encoding="utf-8").write(s)
print("OK: IOLog instrument added; backup -> " + K + ".s96-pre-diag.bak")
