#!/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped
echo "--- file type:"; file "$K" | head -2
echo "--- nm line count (stripped):"; nm "$K" 2>&1 | wc -l
echo "--- nm line count (unstripped):"; nm "$U" 2>&1 | wc -l
echo "--- unstripped grep keep_valid:"; nm "$U" 2>/dev/null | grep -i keep_valid | head
echo "--- unstripped grep star_cs:"; nm "$U" 2>/dev/null | grep -i "star_cs" | head
echo "--- stripped grep cs_invalid_page:"; nm "$K" 2>/dev/null | grep "_cs_invalid_page" | head
echo "--- obj-level check:"; nm /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o 2>/dev/null | grep -i "keep_valid" | head
echo "--- obj strings:"; strings /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o | grep -i "keep_valid" | head
