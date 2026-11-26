#!/bin/bash
# s92: the decisive question — is miniamfi_vnode_check_signature actually reached?
# The hook path: exec_check_permissions / mac_vnode_check_signature -> policy.
# Check mac_vnode_check_signature call site exists in our kern_exec.o and in vfs stuff.
echo "===WHO-CALLS-mac_vnode_check_signature==="
grep -rn "mac_vnode_check_signature\|vnode_check_signature" /root/star26/star-native/bsd/kern/kern_exec.c /root/star26/star-native/bsd/vfs/vfs_support.c /root/star26/star-native/security/mac_vfs.c 2>/dev/null | head -10
echo "===MAC_VFS-BUILD==="
ls /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/security/RELEASE/ 2>/dev/null | head -20
echo "===AMFI-HOOK-IN-BSD==="
grep -rn "check_signature" /root/star26/star-native/bsd/ --include='*.c' 2>/dev/null | grep -v minimac | head -10
