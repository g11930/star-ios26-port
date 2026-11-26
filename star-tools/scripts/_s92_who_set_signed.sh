#!/bin/bash
# s92: final causality verification.
# Q1: cs_flags=0x26000000 in SecTask log — which proc's flags are these?
# Q2: what does csproc_get return for backboardd? We need kernel-side flag at exec time.
# The value 0x26000000 = CS_SIGNED(0x20000000)|CS_PLATFORM_BINARY(0x04000000).
# On real iOS, ad-hoc platform binaries show 0x26000001 (|CS_VALID).
# So exec produced SIGNED+PLATFORM but not VALID — i.e. load_result.csflags lacked CS_VALID
# because ip_csflags &= ~CS_VALID (exec_mach_imgact line 2281) ran: load_result.csflags&CS_VALID==0.
# Why would load_result lack CS_VALID? blob->csb_flags |= CS_VALID at 4102 only when
# cs_validate_csblob succeeded. If backboardd has NO embedded signature (unsigned binary),
# load_code_signature is never called and csflags stays 0 -> CS_VALID cleared.
# But then who set CS_SIGNED|CS_PLATFORM_BINARY? miniamfi_vnode_check_signature —
# but that's only called when there IS a blob...
# UNLESS: the injected sbmetal dylib path (exec_add_apple_individual... ) or
# amfi get_out_of_my_way semantics set CS_SIGNED elsewhere.
# Find every site setting CS_SIGNED in our tree:
grep -rn 'CS_SIGNED' /root/star26/star-native/bsd/kern/kern_exec.c | head -10
echo "===OTHER-SITES==="
grep -rn 'cs_flags |= CS_SIGNED\|csflags |= CS_SIGNED\|proc_csflags_set(p, CS_SIGNED' /root/star26/star-native/bsd/kern/*.c | head -10
echo "===MINIMAC-SYSCALL-SITES==="
grep -n 'CS_SIGNED' /root/star26/star-native/bsd/kern/kern_minimac.c | head -10
