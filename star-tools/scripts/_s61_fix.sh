#!/bin/bash
# fix star_msgprobe private macros (define as 1) + add osfmk/osfmk include path
f=/root/star26/star-native/bsd/dev/star/star_msgprobe.c
sed -i 's|^#define MACH_KERNEL_PRIVATE$|#define MACH_KERNEL_PRIVATE 1|' "$f"
sed -i 's|^#define XNU_KERNEL_PRIVATE$|#define XNU_KERNEL_PRIVATE 1|' "$f"
sed -i 's|^#define BSD_KERNEL_PRIVATE$|#define BSD_KERNEL_PRIVATE 1|' "$f"

m=/root/star26/star-native/bsd/conf/Makefile.arm64
sed -i 's|^star_msgprobe.o_INCFLAGS += -I$(SRCROOT)/osfmk$|star_msgprobe.o_INCFLAGS += -I$(SRCROOT)/osfmk -I$(SRCROOT)/osfmk/osfmk|' "$m"

grep -n 'PRIVATE 1' "$f" | head -4
grep -n star_msgprobe "$m"
