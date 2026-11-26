#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
ls -la --time-style=+%m-%d_%H:%M "$K"
echo "--- STARX format string present:"
strings -a "$K" | grep -n 'STARX' | head
echo "--- per-tag count:"
for t in LIP_ENTER LIP_SCRATCH LIP_TRY LIP_RET LIPA_ENTER LIPA_COPYOUT LIPA_EXEC LIPA_RET \
         ME_ENTER ME_CLONE ME_ACT ME_SWITCH EAI_ALLOC EAI_NAMEI EAI_PERM EAI_RDWR \
         EAI_IMGACT EAI_EXIT LM_ENTER LM_PARSE AES_ENTRY; do
    n=$(strings -a "$K" | grep -c -- "$t")
    printf '  %-14s %s\n' "$t" "$n"
done
echo "--- milestone strings (star_display_handoff):"
strings -a "$K" | grep -e 'star: milestone' -e 'star_display: handoff' | head
echo "--- symbol presence:"
/root/star-build/xnu-deps/host/bin/llvm-nm "$K" 2>/dev/null | grep -E ' _?(star_trace|star_trace_s|star_display_milestone|loader_log_line)$| [Tt] _?star_trace'
