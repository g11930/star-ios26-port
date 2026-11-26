#!/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "--- nm keep_valid:"
nm "$K" 2>/dev/null | grep -i "keep_valid"
echo "--- startup section entries mentioning keep_valid:"
strings "$K" | grep -i "keep_valid_init"
echo "--- otool-ish: section names"
python3 - <<'PY'
import subprocess
K="/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
out=subprocess.run(["nm","-m",K],capture_output=True,text=True).stdout
for l in out.splitlines():
    if "keep_valid" in l or "cs_invalid_page" in l or "process_signature" in l:
        print(l)
PY
