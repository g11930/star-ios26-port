#!/bash
cd /root/star26/star-native || exit 1
echo "===== A) kern_cs.c 100-200 (cs_init guards) ====="
sed -n '100,200p' bsd/kern/kern_cs.c
echo
echo "===== B) where cs_invalid_page / CS_VALID clear path is triggered ====="
grep -rn "cs_invalid_page\|cs_process_invalidated" --include=*.c --include=*.h osfmk bsd 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "===== C) compile flags for security/mac_vfs.o ====="
python3 - <<'PY'
import json
p="/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/compile_commands.json"
d=json.load(open(p))
for e in d:
    f=e.get("file","")
    if "mac_vfs.c" in f or "kern_minimac.c" in f:
        args=e.get("arguments",[])
        print(f)
        print("   CONFIG_MACF in flags:", any(a=="CONFIG_MACF" for a in args))
        print("   count args:", len(args))
PY
echo
echo "===== D) unstripped nm check ====="
nm BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped 2>/dev/null | grep -iE "mac_policy_register|mac_policy_list|mac_vnode_check_signature" | head -10
echo
echo "===== DONE ====="
