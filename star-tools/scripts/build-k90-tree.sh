#!/bin/bash
# Build the fully assembled K90 xnu-12377.121.6 tree on Linux, reusing the
# host toolchain that already linked the stock 12377 feasibility kernel (build24).
# Pure host side: nothing is flashed, no device is touched.
set -e
TREE=/root/star26/kbuild/xnu-12377.121.6
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
export XNU_SDK_VERSION=${XNU_SDK_VERSION:-16.5}
export XNU_SDK_PATH=/root/star-build/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk
export XNU_PLATFORM_PATH=/root/star-build/xnu-deps/sdk/Platforms/iPhoneOS.platform
export RC_DARWIN_KERNEL_VERSION=${RC_DARWIN_KERNEL_VERSION:-25.6.0}
cd "$TREE" || exit 1
exec make XCRUN=/root/star-build/xnu-deps/host/bin/xcrun \
  IIG=/root/xnu26-test/bin/iig XNU26_IIG_PLACEHOLDER=1 \
  MEMORY_SIZE=7516192768 SYSCTL_HW_PHYSICALCPU=8 SYSCTL_HW_LOGICALCPU=16 \
  MIGCC=/root/xnu26-test/bin/xnu26-migcc \
  SDKROOT=iphoneos ARCH_CONFIGS=ARM64 MACHINE_CONFIGS=BCM2837 \
  KERNEL_CONFIGS=RELEASE ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG=arm64 \
  BUILD_WERROR=0 BUILD_LTO=0 DO_CTFMERGE=0 KEXT_CREATE_SYMBOL_SET=/usr/bin/true \
  HOST_CC="clang -include /root/star-build/xnu-deps/hostinc/hostcompat.h -I/root/star-build/xnu-deps/hostinc -Wno-unused-command-line-argument -Wno-error=implicit-function-declaration" \
  HOST_FLEX=flex HOST_BISON=bison HOST_GM4=m4 \
  CC=/root/xnu26-test/bin/xnu26-clang CXX=/root/xnu26-test/bin/xnu26-clang++ LOGCOLORS=n "$@"
