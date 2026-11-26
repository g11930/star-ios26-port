#!/usr/bin/env python3
# s96 step2: in miniamfi_vnode_check_signature(), set CS_VALID when accepting a signature.
# Boot-arg guarded (star_cs_valid=1), default off. Single variable vs s95.
import sys, os, shutil
K = "/root/star26/star-native/bsd/kern/kern_minimac.c"
s = open(K, encoding="utf-8").read()
if "star_cs_valid" in s:
    print("FAIL: already patched"); sys.exit(1)

# 1) add guarded flag + boot-arg parser before the hook (after minimac_policy_init decl)
anchor = "void minimac_policy_init(void);\n\n"
decl = """void minimac_policy_init(void);

/* S96: complement CS_SIGNED with CS_VALID so SecTask/entitlement reads
 * (which require CS_VALID|CS_DEBUGGED) succeed for platform binaries.
 * Boot-arg guarded, default off. */
static int star_cs_valid = 0;
__startup_func
static void
star_cs_valid_init(void)
{
\tPE_parse_boot_argn("star_cs_valid", &star_cs_valid, sizeof(star_cs_valid));
}
STARTUP(CODESIGNING, STARTUP_RANK_FIRST, star_cs_valid_init);

"""
if anchor not in s:
    print("FAIL: decl anchor missing"); sys.exit(1)
s = s.replace(anchor, decl, 1)

# 2) add CS_VALID in the hook after CS_SIGNED
old = """\t*cs_flags |= CS_SIGNED;
\tif (*cs_flags & CS_ADHOC) {
\t\t*cs_flags |= CS_PLATFORM_BINARY;
\t}
\treturn 0;
"""
new = """\t*cs_flags |= CS_SIGNED;
\tif (*cs_flags & CS_ADHOC) {
\t\t*cs_flags |= CS_PLATFORM_BINARY;
\t}
\tif (star_cs_valid) {
\t\t*cs_flags |= CS_VALID;
\t}
\treturn 0;
"""
if old not in s:
    print("FAIL: hook anchor missing"); sys.exit(1)
s = s.replace(old, new, 1)

shutil.copy2(K, K + ".s95-pre-step2.bak")
open(K, "w", encoding="utf-8").write(s)
print("OK: MAC hook CS_VALID patch applied; backup -> " + K + ".s95-pre-step2.bak")
