#!/bin/bash
KB=/root/star26/kbuild/xnu-12377.121.6
SN=/root/star26/star-native
echo "=== kbuild: display / gpu iokit files ==="
ls $KB/iokit/Kernel | grep -iE 'MiniF|Annibale' | head
echo
echo "=== kbuild: P34 probe present? ==="
grep -c 'P34' $KB/iokit/Kernel/MiniIOMobileFramebuffer.cpp 2>/dev/null
echo "=== star-native: P34 probe count ==="
grep -c 'P34' $SN/iokit/Kernel/MiniIOMobileFramebuffer.cpp 2>/dev/null
echo
echo "=== kbuild: adreno8 files ==="
ls $KB/bsd/dev/adreno8/ | head -20
echo
echo "=== kbuild: does its Makefile list adreno8 + annibale? ==="
grep -n 'adreno8\|annibale' $KB/bsd/dev/Makefile 2>/dev/null | head -20
echo
echo "=== diff summary of iokit/Kernel between trees ==="
for f in MiniIOMobileFramebuffer.cpp MiniFramebufferUserClient.inc MiniFramebufferFlip.inc AnnibaleGPU.cpp IOUserClient.cpp; do
  if [ -f $KB/iokit/Kernel/$f ] && [ -f $SN/iokit/Kernel/$f ]; then
    printf "%-40s kbuild=%6d star=%6d\n" "$f" "$(wc -l < $KB/iokit/Kernel/$f)" "$(wc -l < $SN/iokit/Kernel/$f)"
  else
    printf "%-40s kbuild=%s star=%s\n" "$f" "$([ -f $KB/iokit/Kernel/$f ] && echo yes || echo MISSING)" "$([ -f $SN/iokit/Kernel/$f ] && echo yes || echo MISSING)"
  fi
done
