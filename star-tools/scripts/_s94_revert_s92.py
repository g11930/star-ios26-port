#!/usr/bin/env python3
# 从当前源码树还原 s92 探针：恢复 mach_loader.c 到 s90 语义（无 star_cs_probe/star_cs_keep_valid）。
# 精确字符串替换，任一锚点缺失即整体失败（不写部分结果）。
import sys, os, shutil
M = "/root/star26/star-native/bsd/kern/mach_loader.c"
BAK = M + ".s94-pre-revert"
s = open(M, encoding="utf-8").read()

if "star_cs_probe" not in s:
    print("FAIL: no s92 probe found (already reverted?)"); sys.exit(1)

# --- block 1: the whole S92 comment + decls + bootargs fn + STARTUP ---
b1_start = "/*\n * S92: the initial-page validation loop below clears CS_VALID whenever"
b1_end = "STARTUP(CODESIGNING, STARTUP_RANK_FIRST, star_cs_bootargs);\n"
i = s.find(b1_start)
j = s.find(b1_end)
if i < 0 or j < 0 or j < i:
    print("FAIL: block1 anchors missing"); sys.exit(1)
j += len(b1_end)
s = s[:i] + s[j:]

# --- block 2a: remove star_cs_probe trace --- 
probe = """\t\t\t\t\t\t\tif (star_cs_probe) {
\t\t\t\t\t\t\t\tstar_trace("CS_INITPAGE_BAD", (long long)(file_offset + off),
\t\t\t\t\t\t\t\t    ((long long)valid << 32) | (long long)(tainted & 0xffffffff));
\t\t\t\t\t\t\t\tstar_trace_s("CS_INITPAGE_F", vp->v_name,
\t\t\t\t\t\t\t\t    (long long)result->csflags);
\t\t\t\t\t\t\t\tstar_trace("CS_INITPAGE_CTX", (long long)alloc_size, (long long)cmds_size);
\t\t\t\t\t\t\t}
"""
if probe not in s:
    print("FAIL: probe trace block missing"); sys.exit(1)
s = s.replace(probe, "", 1)

# --- block 2b: restore unconditional clear ---
guarded = """\t\t\t\t\t\t\tif (star_cs_keep_valid) {
\t\t\t\t\t\t\t\t/* S92: keep CS_VALID set; see star_cs_keep_valid above. */
\t\t\t\t\t\t\t} else {
\t\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;
\t\t\t\t\t\t\t}
"""
orig = "\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;\n"
if guarded not in s:
    print("FAIL: keep_valid guard block missing"); sys.exit(1)
s = s.replace(guarded, orig, 1)

# --- verify no residue ---
for tag in ("star_cs_probe", "star_cs_keep_valid", "CS_INITPAGE_BAD", "CS_INITPAGE_F", "CS_INITPAGE_CTX", "S92:"):
    if tag in s:
        print("FAIL: residue after revert: " + tag); sys.exit(1)

shutil.copy2(M, BAK)
open(M, "w", encoding="utf-8").write(s)
print("OK: mach_loader.c reverted to s90 semantics; backup -> " + BAK)
