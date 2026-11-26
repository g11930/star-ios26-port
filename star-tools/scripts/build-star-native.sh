#!/bin/bash
# Build the star-native minimal kernel (no K90 platform drivers). Host-side only.
TREE=/root/star26/star-native
LOG=/mnt/c/ios26/star-native-build.log
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
export XNU_SDK_VERSION=${XNU_SDK_VERSION:-16.5}
export XNU_SDK_PATH=/root/star-build/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk
export XNU_PLATFORM_PATH=/root/star-build/xnu-deps/sdk/Platforms/iPhoneOS.platform
export RC_DARWIN_KERNEL_VERSION=${RC_DARWIN_KERNEL_VERSION:-25.6.0}
# The kernel itself stays arm64.  SM8350 has no FEAT_PAuth: running an arm64e
# kernel on it only pulls in __arm64e__ branches and dies before arm_vm_init.
# arm64e *user space* is already supported by STAR_ARM64E_USERLAND in
# pexpert/pexpert/arm64/BCM2837.h (arm_arch reported as CPU_ARCH_ARMv8E,
# cpu_subtype as CPU_SUBTYPE_ARM64E, PAC/AUT emulated by sleh.c).  This is the
# same arrangement as warsaw's REDWOOD_ARM64E_USERLAND and is what both
# reference ports do.  See 2026-11-15 memory notes.
export XNU_TARGET_TRIPLE=arm64-apple-ios${XNU_SDK_VERSION}
cd "$TREE" || exit 1
set +e
make XCRUN=/root/star-build/xnu-deps/host/bin/xcrun \
  IIG=/root/xnu26-test/bin/iig XNU26_IIG_PLACEHOLDER=1 \
  MEMORY_SIZE=7516192768 SYSCTL_HW_PHYSICALCPU=8 SYSCTL_HW_LOGICALCPU=16 \
  MIGCC=/root/xnu26-test/bin/xnu26-migcc \
  SDKROOT=iphoneos ARCH_CONFIGS=ARM64 MACHINE_CONFIGS=BCM2837 \
  KERNEL_CONFIGS=RELEASE ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG=arm64 \
  BUILD_WERROR=0 BUILD_LTO=0 DO_CTFMERGE=0 KEXT_CREATE_SYMBOL_SET=/usr/bin/true \
  HOST_CC="clang -include /root/star-build/xnu-deps/hostinc/hostcompat.h -I/root/star-build/xnu-deps/hostinc -Wno-unused-command-line-argument -Wno-error=implicit-function-declaration" \
  HOST_FLEX=flex HOST_BISON=bison HOST_GM4=m4 \
  CC=/root/xnu26-test/bin/xnu26-clang CXX=/root/xnu26-test/bin/xnu26-clang++ LOGCOLORS=n \
  "$@" > "$LOG" 2>&1
rc=$?
echo "BUILD_EXIT=$rc" >> "$LOG"
tail -45 "$LOG"
# --- gate: the kalloc section constants must match THIS kernel (stage 8) ---
if [ "$rc" -eq 0 ]; then
	echo "--- stage 8 gate: kalloc section constants ---" | tee -a "$LOG"
	python3 /mnt/d/桌面/star26-deps/scripts/stage8-kalloc-backfill.py --check 2>&1 | tail -7 | tee -a "$LOG"
fi

exit $rc
