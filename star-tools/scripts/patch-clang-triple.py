#!/usr/bin/env python3
"""Make the kernel clang wrapper honour an arm64e target.

xnu26-clang hardcodes `-target arm64-apple-ios16.5`, so `-arch arm64e` never
reaches the front end: the objects stay plain arm64 (no pacibsp/paciasp, no
__auth_got), and only the Mach-O subtype of the linked kernel changed.  A plain
arm64 kernel cannot run the arm64e user space this project exists to run.

Default stays arm64 so the other trees that use this wrapper are unaffected;
build-star-native.sh exports XNU_TARGET_TRIPLE to opt in.
"""
P = "/root/xnu26-test/bin/xnu26-clang"
src = open(P, encoding="utf-8").read()
if "XNU_TARGET_TRIPLE" in src:
    print("wrapper already patched")
    raise SystemExit
old = '-target arm64-apple-ios${XNU_SDK_VERSION:-16.5}'
new = '-target ${XNU_TARGET_TRIPLE:-arm64-apple-ios${XNU_SDK_VERSION:-16.5}}'
assert old in src, "target string not found"
src = src.replace(old, new, 1)
open(P, "w", encoding="utf-8").write(src)
print("patched", P)
print(open(P, encoding="utf-8").read().splitlines()[-3])
