#!/bin/bash
# What does our own tree do about arm64e user space? Four places matter:
#   1. osfmk/arm/cpuid.c      -- arm_arch reported to user space
#   2. mach_loader.c          -- ml_grade_binary(), what CPU subtypes it accepts
#   3. osfmk/arm64/sleh.c     -- PAC instruction emulation and its boot-arg
#   4. vm_shared_region.c / vm_dyld_pager.c -- arm64e pointer formats
T=/root/star26/star-native
echo "######## 1. cpuid.c arm_arch"
grep -n 'arm_arch\|CPU_ARCH_ARMv8E\|HAS_APPLE_PAC\|REDWOOD' $T/osfmk/arm/cpuid.c | head -20
echo
echo "######## 2. ml_grade_binary"
grep -rn 'ml_grade_binary' $T/bsd/kern/*.c $T/osfmk/kern/*.c 2>/dev/null | head -10
grep -n 'CPU_SUBTYPE_ARM64E\|grade_binary' $T/bsd/kern/mach_loader.c | head -20
echo
echo "######## 3. sleh pac emu"
grep -n 'pac_emu\|PAC_EMU\|pac_emu_instruction' $T/osfmk/arm64/sleh.c | head -20
echo
echo "######## 4. vm pointer formats"
grep -n 'DYLD_CHAINED_PTR_ARM64E\|__has_feature(ptrauth_calls)\|HAS_APPLE_PAC' $T/osfmk/vm/vm_dyld_pager.c | head -20
echo "--- vm_shared_region"
grep -n 'ptrauth_calls\|DYLD_CHAINED_PTR_ARM64E' $T/osfmk/vm/vm_shared_region.c | head -20
echo
echo "######## 5. our board config"
ls $T/pexpert/pexpert/arm64/ | grep -i -e star -e annibale -e bcm | head
echo "--- ARM_PAN / HAS_APPLE_PAC in our config"
grep -rn 'HAS_APPLE_PAC\|ARM_PAN_AVAILABLE\|REDWOOD' $T/pexpert/pexpert/arm64/*.h 2>/dev/null | head -10
