#!/bin/bash
cd /root/star26/star-native || exit 1
echo "=== phystokv / physmap ==="
grep -rn "phystokv\|PHYSMAP\|ml_static_ptovirt" osfmk/arm/*.h osfmk/arm64/*.h osfmk/arm/pmap/*.h 2>/dev/null | head -12
echo "=== pmap_find_phys ==="
grep -rn "pmap_find_phys" osfmk/arm/pmap/*.h osfmk/arm/*.h 2>/dev/null | head -5
echo "=== kdp user read ==="
grep -rn "kdp_machine_vm_read\|kdp_vm_read" osfmk/kdp/*.c osfmk/kdp/*.h 2>/dev/null | head -8
echo "=== stackshot sysctl? ==="
grep -rn "stack_snapshot_with_flags\|kern_stackshot\|stackshot" osfmk/kern/stackshot.h 2>/dev/null | head -8
echo "=== get_saved_state_fp decl ==="
sed -n '760,790p' osfmk/mach/arm/thread_status.h
