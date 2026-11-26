#!/usr/bin/env python3
# S93 (scheme A, refined): guard cs_invalid_page's CS_VALID clear behind
# boot-arg "star_cs_keep_valid". One variable, reversible, default-off.
import sys, os
CS = "/root/star26/star-native/bsd/kern/kern_cs.c"

def fail(m):
    print("FAIL:", m, file=sys.stderr); sys.exit(1)

s = open(CS, encoding="utf-8").read()
if "star_cs_keep_valid" in s:
    fail("already patched")

# 1) declaration next to cs_debug
a = "int cs_debug = 0;\n"
if a not in s: fail("cs_debug decl anchor missing")
s = s.replace(a, a +
    "\n/* S93: keep CS_VALID across failed page validations (boot-arg gated). */\n"
    "static int star_cs_keep_valid = 0;\n"
    "static int star_kv_logged = 0;\n", 1)

# 2) boot-arg parse next to cs_debug parse
a = '\tPE_parse_boot_argn("cs_debug", &cs_debug, sizeof(cs_debug));\n'
if a not in s: fail("cs_debug parse anchor missing")
s = s.replace(a, a +
    '\tPE_parse_boot_argn("star_cs_keep_valid", &star_cs_keep_valid,\n'
    '\t    sizeof(star_cs_keep_valid));\n', 1)

# 3) guard the clear
old = "\t\tif (flags & CS_VALID) {\n" \
      "\t\t\tflags &= ~CS_VALID;\n" \
      "\t\t\tcs_procs_invalidated++;\n" \
      "\t\t\tverbose = 1;\n" \
      "\t\t\tproc_csflags_update(p, flags);\n" \
      "\t\t\tcs_process_invalidated(NULL);\n" \
      "\t\t} else {\n" \
      "\t\t\tproc_csflags_update(p, flags);\n" \
      "\t\t}\n"
new = "\t\tif (flags & CS_VALID) {\n" \
      "\t\t\tif (star_cs_keep_valid) {\n" \
      "\t\t\t\t/* S93: retain CS_VALID so SecTask/entitlement reads\n" \
      "\t\t\t\t * (which require CS_VALID|CS_DEBUGGED) keep working. */\n" \
      "\t\t\t\tif (star_kv_logged < 8) {\n" \
      "\t\t\t\t\tstar_kv_logged++;\n" \
      "\t\t\t\t\tIOLog(\"star_kv: pid %d[%s] KEEP CS_VALID would-clear 0x%x\\n\",\n" \
      "\t\t\t\t\t    proc_getpid(p), p->p_comm, (unsigned int)flags);\n" \
      "\t\t\t\t}\n" \
      "\t\t\t\tproc_csflags_update(p, flags);\n" \
      "\t\t\t} else {\n" \
      "\t\t\t\tflags &= ~CS_VALID;\n" \
      "\t\t\t\tcs_procs_invalidated++;\n" \
      "\t\t\t\tverbose = 1;\n" \
      "\t\t\t\tproc_csflags_update(p, flags);\n" \
      "\t\t\t\tcs_process_invalidated(NULL);\n" \
      "\t\t\t}\n" \
      "\t\t} else {\n" \
      "\t\t\tproc_csflags_update(p, flags);\n" \
      "\t\t}\n"
if old not in s: fail("clear block anchor missing")
s = s.replace(old, new, 1)

open(CS, "w", encoding="utf-8").write(s)
print("OK: kern_cs.c patched (single variable: star_cs_keep_valid)")
