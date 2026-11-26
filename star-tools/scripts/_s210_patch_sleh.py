#!/usr/bin/env python3
# Restore pac_patch category-mask semantics in star-native sleh.c.
# 3 edit sites: (1) mask defines + variable comment, (2) encode() gains mask arg
# with per-category gating, (3) page() parses raw mask and passes it.
import sys

P = "/root/star26/star-native/osfmk/arm64/sleh.c"
src = open(P, "r", encoding="utf-8").read()

edits = []

# --- site 1: category defines + variable comment ---
old1 = """ * Boot-arg pac_patch=0 restores pure emulation for A/B comparison.
 */
static int      pac_patch_enabled = -1;
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;"""
new1 = """ * Boot-arg pac_patch is a CATEGORY MASK (restored for safe speedup):
 *   0x1 PAC/AUT/XPAC+PACGA -> nop   0x2 RETAA/RETAB -> ret
 *   0x4 BRAA/BLRAA (+Z)   -> br/blr 0x8 LDRAA/LDRAB -> ldr/ldur
 *   0 = pure emulation (slow but safe), 15 = all (UNSAFE: mount-phase-2 panic).
 * Default 0: never go faster unless the kernel cmdline explicitly asks for it.
 */
#define PAC_PATCH_PAC   0x1u
#define PAC_PATCH_RET   0x2u
#define PAC_PATCH_BR    0x4u
#define PAC_PATCH_LDRA  0x8u

static int      pac_patch_enabled = -1;   /* -1 = lazy-init; else category mask */
static uint64_t pac_patch_pages;
static uint64_t pac_patch_instrs;"""
edits.append(("site1 defines+var", old1, new1))

# --- site 2a: encode signature ---
old2a = """static uint32_t
pac_patch_encode(uint32_t instr)
{
	uint32_t base, rn, rt, op;
	int32_t  imm9, imm10, byte_off;

	/* PAC / AUT / XPAC (data-processing, one source). */
	if ((instr & 0xffff0000u) == 0xdac10000u) {
		op = (instr >> 10) & 0x3fu;"""
new2a = """static uint32_t
pac_patch_encode(uint32_t instr, uint32_t mask)
{
	uint32_t base, rn, rt, op;
	int32_t  imm9, imm10, byte_off;

	/* PAC / AUT / XPAC (data-processing, one source). */
	if ((instr & 0xffff0000u) == 0xdac10000u) {
		if ((mask & PAC_PATCH_PAC) == 0) return 0;
		op = (instr >> 10) & 0x3fu;"""
edits.append(("site2a encode sig + PAC gate", old2a, new2a))

# --- site 2b: PACGA gate ---
old2b = """	/* PACGA: no APGA key, so the computed tag is zero. */
	if ((instr & 0xffe0fc00u) == 0x9ac03000u) {
		return 0xaa1f03e0u | (instr & 0x1fu);   /* mov Xd, XZR */
	}"""
new2b = """	/* PACGA: no APGA key, so the computed tag is zero. */
	if ((instr & 0xffe0fc00u) == 0x9ac03000u) {
		if ((mask & PAC_PATCH_PAC) == 0) return 0;
		return 0xaa1f03e0u | (instr & 0x1fu);   /* mov Xd, XZR */
	}"""
edits.append(("site2b PACGA gate", old2b, new2b))

# --- site 2c: RET gate ---
old2c = """	/* RETAA / RETAB. */
	if (instr == 0xd65f0bffu || instr == 0xd65f0fffu) {
		return 0xd65f03c0u;                     /* ret */
	}"""
new2c = """	/* RETAA / RETAB. */
	if (instr == 0xd65f0bffu || instr == 0xd65f0fffu) {
		if ((mask & PAC_PATCH_RET) == 0) return 0;
		return 0xd65f03c0u;                     /* ret */
	}"""
edits.append(("site2c RET gate", old2c, new2c))

# --- site 2d: BR gate (before switch) ---
old2d = """	/* Authenticated indirect branches: Rn is the plain target. */
	base = instr & 0xfffffc00u;
	rn = (instr >> 5) & 0x1fu;
	switch (base) {"""
new2d = """	/* Authenticated indirect branches: Rn is the plain target. */
	if ((mask & PAC_PATCH_BR) == 0) return 0;
	base = instr & 0xfffffc00u;
	rn = (instr >> 5) & 0x1fu;
	switch (base) {"""
edits.append(("site2d BR gate", old2d, new2d))

# --- site 2e: LDRA gate ---
old2e = """	if ((instr & 0xff200400u) == 0xf8200400u) {
		rt = instr & 0x1fu;"""
new2e = """	if ((instr & 0xff200400u) == 0xf8200400u) {
		if ((mask & PAC_PATCH_LDRA) == 0) return 0;
		rt = instr & 0x1fu;"""
edits.append(("site2e LDRA gate", old2e, new2e))

# --- site 3a: page() mask parse ---
old3a = """	if (__improbable(pac_patch_enabled < 0)) {
		uint32_t v = 1;
		(void) PE_parse_boot_argn("pac_patch", &v, sizeof(v));
		pac_patch_enabled = v ? 1 : 0;
	}
	if (!pac_patch_enabled) {
		return;
	}"""
new3a = """	if (__improbable(pac_patch_enabled < 0)) {
		uint32_t v = 0;   /* default: pure emulation; cmdline opts in */
		(void) PE_parse_boot_argn("pac_patch", &v, sizeof(v));
		pac_patch_enabled = (int)(v & 0xfu);
	}
	if (pac_patch_enabled == 0) {
		return;
	}"""
edits.append(("site3a mask parse", old3a, new3a))

# --- site 3b: encode() call site ---
old3b = "\t\tuint32_t now = pac_patch_encode(insns[i]);"
new3b = "\t\tuint32_t now = pac_patch_encode(insns[i], (uint32_t)pac_patch_enabled);"
edits.append(("site3b call site", old3b, new3b))

# apply with strict uniqueness assertions
out = src
for name, old, new in edits:
    n = out.count(old)
    if n != 1:
        print(f"FAIL {name}: expected 1 match, got {n}")
        sys.exit(1)
    out = out.replace(old, new, 1)
    print(f"OK   {name}")

open(P + ".s210-pre", "w", encoding="utf-8").write(src)  # backup (not .bak: build ignores .bak)
open(P, "w", encoding="utf-8").write(out)
print(f"DONE {P}")
print(f"backup -> {P}.s210-pre ({len(src)} bytes)")
print(f"new     {len(out)} bytes")
