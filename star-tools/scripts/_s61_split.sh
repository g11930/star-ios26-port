#!/bin/bash
set -e
S=/root/star26/star-native

# 1. remove the mixed-TU INCFLAGS workaround (no longer needed)
sed -i '/# s61: star_msgprobe reads osfmk IPC internals directly/,+1d' "$S/bsd/conf/Makefile.arm64"
grep -c star_msgprobe "$S/bsd/conf/Makefile.arm64" || true

# 2. remove the types.h shim (no longer needed)
rm -f "$S/osfmk/types.h"

# 3. deploy the two halves
cp /mnt/d/桌面/star26-deps/src/star_msgprobe.c   "$S/bsd/dev/star/star_msgprobe.c"
cp /mnt/d/桌面/star26-deps/src/star_msgprobe_k.c "$S/osfmk/kern/star_msgprobe_k.c"

# 4. register the osfmk half
if ! grep -q star_msgprobe_k "$S/osfmk/conf/files"; then
    sed -i 's|^osfmk/kern/mach_loader.c.*|&\nosfmk/kern/star_msgprobe_k.c\t\tstandard|' "$S/osfmk/conf/files" || true
fi
grep -n 'star_msgprobe' "$S/osfmk/conf/files" | head -3
grep -n 'star_msgprobe' "$S/bsd/conf/files" | head -3
echo DEPLOY-DONE
