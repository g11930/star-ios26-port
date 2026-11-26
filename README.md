# star-ios26-port

XNU 12377.121.6 (iOS 26) ported to Xiaomi 11 Ultra (SM8350 / star).

This repository contains our porting work on top of Apple's open-source
XNU 12377.121.6 baseline. Start from apple-oss-distributions/xnu at tag
xnu-12377.121.6 and overlay this tree.

## Layout
- Kernel source tree at repository root (modified XNU):
  - arm64 kernel, arm64e userland; PAC emulated in software in
    osfmk/arm64/sleh.c (SM8350 has no FEAT_PAuth hardware).
  - osfmk/vm/vm_shared_region*.c: 4k shared-region-slide pager patch.
  - pexpert/pexpert/arm64/BCM2837.h: platform configuration.
  - bsd/dev/star/: storage, display and input drivers.
- star-tools/scripts/: build, patch and packaging scripts.

## Baseline
- Upstream: https://github.com/apple-oss-distributions/xnu @ ac9718f
  (xnu-12377.121.6).
- Our work: snapshot 92fbb2e (pre-clean) plus subsequent edits.
- Debug backups (*.bak, *.sNN-pre) and build artifacts (BUILD/) are excluded.

## Status
Experimental. Boots to desktop on device; Wi-Fi / audio / camera drivers pending.

## AI one-click build

Want an agent to build a bootable image for you? See [AI_BUILD.md](AI_BUILD.md)
for the exact, gated pipeline (tree build -> pager patch -> compile with kalloc
gate -> single-variable packaging -> flash criteria). One command once the
toolchain and device baseline parts are in place:

    bash star-tools/ai-build.sh

Note: the kernel source and scripts are here, but the cross-toolchain, XNU SDK
and device-extracted baseline parts (loader/ramdisk/rdimage/memsize/identity)
are prerequisites, not included in this repo.
