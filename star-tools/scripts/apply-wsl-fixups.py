#!/usr/bin/env python3
"""Overlay the Linux-host toolchain fixes onto a fully assembled K90 xnu-12377 tree.

The K90 patch series already carries the Linux adaptations (Makefile nproc,
MakeInc.*, doconf, MASTER.arm64.bcm2837, BCM2837.h, ppl/, tunables/) --
verified byte-identical against the previously linked feasibility tree.
Only these five items are Linux-toolchain-specific and must be overlaid:

  1. iokit/IOKit/IOExtensiblePaniclog.h : Apple's closed iig is unavailable, so
     replace WithDispatch structors and inject the *_Impl declarations.
  2. osfmk/arm64/corecrypto/sha256_compress_arm64.s : name the crypto ISA for
     upstream clang 18's integrated assembler.
  3. osfmk/arm64/corecrypto/arm64_isa_compatibility.h : the v-form gate must
     also match non-Apple clang (K90's patch 40 already does this; only a
     comment differs, so no change is needed).
  4. conf/files* : comment out sources absent from the public tarball.
  5. iokit/Tests entries : need generated DriverKit test headers, disable.

Idempotent. Usage: python3 apply-wsl-fixups.py <assembled-tree>
"""
import os
import re
import shutil
import sys

FEAS = "/root/xnu26-test/xnu-12377.121.6"
root = sys.argv[1] if len(sys.argv) > 1 else "/root/star26/kbuild/xnu-12377.121.6"
root = os.path.abspath(root)

COPY = [
    "iokit/IOKit/IOExtensiblePaniclog.h",
    "osfmk/arm64/corecrypto/sha256_compress_arm64.s",
]

for rel in COPY:
    src, dst = os.path.join(FEAS, rel), os.path.join(root, rel)
    if not os.path.isfile(src):
        print("MISSING SOURCE", src)
        sys.exit(1)
    shutil.copy2(src, dst)
    print("copied  ", rel)

# 4. conf/files: disable entries whose source is not present.
GENERATED = re.compile(
    r"(\.iig\.(cpp|h)$|_(server|reply|user)\.(c|h)$|sysent\.c$|"
    r"systrace_args\.c$|ioconf\.c$|audit_kevents\.c$|syscalls\.c$)")
MARK = "# [star build] not in the public tarball: "
total = 0
for dirpath, dirnames, filenames in os.walk(root):
    if ".git" in dirpath or os.path.basename(dirpath) != "conf":
        continue
    for name in sorted(filenames):
        if not name.startswith("files"):
            continue
        path = os.path.join(dirpath, name)
        try:
            lines = open(path, encoding="utf-8").read().split("\n")
        except UnicodeDecodeError:
            continue
        out, changed = [], []
        for ln in lines:
            s = ln.strip()
            if not s or s.startswith("#"):
                out.append(ln)
                continue
            src = s.split()[0]
            if (src.startswith(("./", "$", "/", "#")) or "OPTIONS/" in src
                    or GENERATED.search(src)):
                out.append(ln)
                continue
            if not os.path.exists(os.path.join(root, src)):
                out.append(MARK + ln)
                changed.append(src)
            else:
                out.append(ln)
        if changed:
            open(path, "w", encoding="utf-8").write("\n".join(out))
            print("disabled %-28s %d" % (os.path.relpath(path, root), len(changed)))
            for c in changed:
                print("    -", c)
            total += len(changed)
print("conf/files entries disabled:", total)

# 5. iokit/Tests: these need DriverKit test headers that iig would generate.
p = os.path.join(root, "iokit/conf/files")
lines = open(p, encoding="utf-8").read().split("\n")
out, n = [], 0
for ln in lines:
    s = ln.strip()
    if s.startswith("iokit/Tests/") and not s.startswith("#"):
        out.append("# [star build] test-only, needs generated DriverKit test headers: " + ln)
        n += 1
    else:
        out.append(ln)
if n:
    open(p, "w", encoding="utf-8").write("\n".join(out))
print("iokit/Tests entries disabled:", n)

print("DONE", root)
