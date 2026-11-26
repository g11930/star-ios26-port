#!/usr/bin/env python3
"""Verify pac_patch_encode() against real arm64e encodings.

For every sample instruction:
  1. assemble it with llvm-mc (arm64e, +pauth) to get the true encoding
  2. run the same logic as osfmk/arm64/sleh.c:pac_patch_encode()
  3. disassemble the replacement and print both side by side
"""
import re
import subprocess
import sys

TRIPLE = "arm64e-apple-ios"

SAMPLES = [
    "retaa", "retab",
    "braa x8, x9", "brab x8, x9", "braaz x8", "brabz x8",
    "blraa x8, x9", "blrab x8, x9", "blraaz x8", "blrabz x8",
    "pacia x0, x1", "autib x2, x3", "xpaci x4", "pacga x5, x6, x7",
    "ldraa x0, [x1, #16]", "ldraa x10, [x11, #-24]",
    "ldrab x12, [x13, #2040]", "ldraa x14, [x15, #2400]",
    "ldraa x14, [x15, #-2400]",
]


def mc(args, text):
    p = subprocess.run(["llvm-mc", "-triple=" + TRIPLE] + args,
                       input=text, capture_output=True, text=True)
    if p.returncode != 0:
        return None, p.stderr.strip()
    return p.stdout, None


def assemble(lines):
    """Return list of (line, encoding) using -show-encoding."""
    text = "\n".join(lines) + "\n"
    out, err = mc(["-show-encoding"], text)
    if out is None:
        sys.exit("assemble failed: " + err)
    encs = re.findall(r"encoding: \[([^\]]+)\]", out)
    if len(encs) != len(lines):
        sys.exit("encoding count mismatch: %d vs %d" % (len(encs), len(lines)))
    res = []
    for line, e in zip(lines, encs):
        b = [int(x.strip(), 16) for x in e.split(",")]
        assert len(b) == 4, (line, b)
        res.append((line, b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)))
    return res


def disasm(encodings):
    text = "\n".join("0x%02x 0x%02x 0x%02x 0x%02x" % (
        e & 0xff, (e >> 8) & 0xff, (e >> 16) & 0xff, (e >> 24) & 0xff)
        for e in encodings) + "\n"
    out, err = mc(["-disassemble"], text)
    if out is None:
        return ["<disasm failed: %s>" % err] * len(encodings)
    return [l.strip() for l in out.strip().splitlines()
            if l.strip() and not l.strip().startswith(".")]


def encode(instr):
    """Mirror of pac_patch_encode()."""
    if (instr & 0xffff0000) == 0xdac10000:
        op = (instr >> 10) & 0x3f
        if op <= 7 or (op <= 17 and (instr & 0x3e0) == 0x3e0):
            return 0xd503201f          # nop
        return 0
    if (instr & 0xffe0fc00) == 0x9ac03000:
        return 0xaa1f03e0 | (instr & 0x1f)      # mov Xd, XZR
    if instr in (0xd65f0bff, 0xd65f0fff):
        return 0xd65f03c0          # ret
    base = instr & 0xfffffc00
    rn = (instr >> 5) & 0x1f
    if base in (0xd71f0800, 0xd71f0c00, 0xd61f0800, 0xd61f0c00):
        return 0xd61f0000 | (rn << 5)          # br Xn
    if base in (0xd73f0800, 0xd73f0c00, 0xd63f0800, 0xd63f0c00):
        return 0xd63f0000 | (rn << 5)          # blr Xn
    if (instr & 0xff200400) == 0xf8200400:
        rt = instr & 0x1f
        imm9 = (instr >> 12) & 0x1ff
        imm10 = imm9 - 512 if ((instr >> 22) & 1) else imm9
        if instr & 0x800:
            return 0
        if imm10 >= 0:
            return 0xf9400000 | ((imm10 & 0xfff) << 10) | (rn << 5) | rt
        if imm10 >= -32:
            byte_off = (imm10 * 8) & 0x1ff
            return 0xf8400000 | (byte_off << 12) | (rn << 5) | rt
        return 0
    return 0


def main():
    pairs = assemble(SAMPLES)
    repl = [encode(e) for _, e in pairs]
    dis = disasm(repl)
    print("%-28s %-12s -> %-12s %s" % ("original", "encoding", "rewrite", "rewritten as"))
    print("-" * 78)
    bad = 0
    for (line, e), r, d in zip(pairs, repl, dis):
        if r == 0:
            print("%-28s 0x%08x -> (keep emulating)  [%s]" % (line, e, d))
            continue
        print("%-28s 0x%08x -> 0x%08x   %s" % (line, e, r, d))
        # idempotency: the replacement must not re-encode
        if encode(r) != 0:
            print("   !! NOT IDEMPOTENT: re-encode gives 0x%08x" % encode(r))
            bad += 1
    print()
    print("non-idempotent: %d" % bad)


if __name__ == "__main__":
    main()
