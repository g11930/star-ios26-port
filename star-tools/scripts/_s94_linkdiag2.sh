#!/bin/bash
T=/root/star26/star-native
OBJ=$T/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== is kern_cs.o in the final link? check linkarguments fully ==="
cat "$OBJ/mach.release.bcm2837.link/mach.release.bcm2837.linkarguments" 2>/dev/null | tr ' ' '\n' | grep -i 'kern_cs\|kern_exec\|mach_loader' | head
echo "=== count object/xml entries mentioning kern_cs in link map ==="
grep -rl 'kern_cs' "$OBJ/mach.release.bcm2837.link/" 2>/dev/null | head
echo "=== the .a DOES have patch (confirmed); does ld use THIS .a? ==="
grep -o '[^ ]*\.a' "$OBJ/mach.release.bcm2837.link/mach.release.bcm2837.linkarguments" 2>/dev/null | head
echo "=== unstripped.noctf has P28EXIT? (kern_exit.o) ==="
strings -a "$OBJ/mach.release.bcm2837.unstripped.noctf" | grep -c P28EXIT
echo "=== unstripped.noctf has kern_cs.o's unique strings? ==="
for s in star_cs_keep_valid 'cs_debug' 'Invalidated flags'; do
  echo -n "$s: "; strings -a "$OBJ/mach.release.bcm2837.unstripped.noctf" | grep -c "$s"
done
echo "=== is there a SECOND kern_cs source compiled into a different object? ==="
grep -rn 'kern_cs' "$T/bsd/kern/Makefile" 2>/dev/null | head
echo "=== s93 kernel: does it have 'Invalidated flags' (kern_cs.c string)? ==="
echo -n "s93: "; strings -a /root/star26/s93/parts/kernel | grep -c 'Invalidated flags'
echo -n "current: "; strings -a "$OBJ/mach.release.bcm2837" | grep -c 'Invalidated flags'
