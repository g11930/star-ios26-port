#!/bin/bash
cd /root/star26/star-native || exit 1
for s in proc_getpid suser vfs_context_kernel vnode_lookup vnode_mount vfs_statfs vnode_put; do
	echo "--- $s"
	grep -rn "$s" bsd/sys bsd/vfs osfmk/kern --include='*.h' 2>/dev/null | head -3
done
