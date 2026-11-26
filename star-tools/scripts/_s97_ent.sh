#!/bash
cd /root/star26/star-native || exit 1
echo "===== A) ubc_subr.c 810-905 (csblob_get_entitlements) ====="
sed -n '810,905p' bsd/kern/ubc_subr.c
echo
echo "===== B) kern_proc.c 3895-3935 (CS_OPS_ENTITLEMENTS_BLOB) ====="
sed -n '3895,3935p' bsd/kern/kern_proc.c
echo
echo "===== C) kern_proc.c 3710-3745 ====="
sed -n '3710,3745p' bsd/kern/kern_proc.c
echo
echo "===== D) kern_cs.c 1795-1830 ====="
sed -n '1795,1835p' bsd/kern/kern_cs.c
echo
echo "===== E) security/mac_vfs.o.json CONFIG_MACF check ====="
grep -o "CONFIG_MACF\"\|CONFIG_MACF_SOCKET_SUBSET" BUILD/obj/RELEASE_ARM64_BCM2837/security/RELEASE/mac_vfs.o.json 2>/dev/null | sort -u
grep -c "\"CONFIG_MACF\"" BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/ubc_subr.o.json 2>/dev/null
echo
echo "===== DONE ====="
