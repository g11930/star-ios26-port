#!/bin/bash
# add star_msgprobe INCFLAGS to bsd/conf/Makefile.arm64
f=/root/star26/star-native/bsd/conf/Makefile.arm64
if grep -q star_msgprobe "$f"; then
    echo already-wired
else
    sed -i 's|^kern_debug.o_INCFLAGS += -I$(SRCROOT)/osfmk$|kern_debug.o_INCFLAGS += -I$(SRCROOT)/osfmk\n\n# s61: star_msgprobe reads osfmk IPC internals directly (ipc_port/ipc_space).\nstar_msgprobe.o_INCFLAGS += -I$(SRCROOT)/osfmk|' "$f"
fi
grep -n star_msgprobe "$f"
