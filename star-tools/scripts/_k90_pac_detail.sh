#!/bin/bash
B=/root/star26/k90ref/kernel/xnu26/patches
echo "=== 36 cpuid.c.patch ==="; cat "$B"/36-osfmk%arm%cpuid.c.patch
echo
echo "=== 78 pe_identify_machine.patch ==="; cat "$B"/78-pexpert%arm%pe_identify_machine.c.patch
echo
echo "=== 40 corecrypto arm64_isa_compatibility.patch ==="; cat "$B"/40-osfmk%arm64%corecrypto%arm64_isa_compatibility.h.patch
echo
echo "=== 63 vm_dyld_pager.patch (前25行) ==="; head -25 "$B"/63-osfmk%vm%vm_dyld_pager.c.patch
