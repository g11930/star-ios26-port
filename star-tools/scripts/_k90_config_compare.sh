#!/bin/bash
OUT=/mnt/c/ios26/k90_vs_star_config.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
W=/root/star26/warsaw-ref
S=/root/star26/hackios-xnu-userland/userland

e "########## 1) K90 v37 cmdline (from status/docs) ##########"
grep -rn -i "cmdline\|boot-arg\|cpufreq\|fb_hz\|touch_lat\|autounlock\|loader_return" "$W/docs/V37-STATUS.md" "$W/docs/STATUS-2026-11-09.md" 2>/dev/null | head -40 >> "$OUT"

e ""
e "########## 2) K90 actual boot script / cmdline files ##########"
find "$W" -type f \( -iname "*cmdline*" -o -iname "*boot*.sh" -o -iname "*args*" \) -printf '%s %p\n' 2>/dev/null | sort -rn | head -20 >> "$OUT"

e ""
e "########## 3) K90 README 上机步骤 (boot-arg list) ##########"
find "$W" -maxdepth 2 -iname "README*" -exec grep -Hn -i "boot-arg\|cmdline\|cpufreq\|autounlock\|fb_hz\|touch_poll\|metal_props" {} \; 2>/dev/null | head -50 >> "$OUT"

e ""
e "########## 4) s94 cmdline ##########"
tr -d '\0' < /root/star26/s94/parts/cmdline >> "$OUT"
echo >> "$OUT"

e ""
e "########## 5) K90 mkcache/jobs: which jobs are shipped (sleepd etc) ##########"
grep -rn -i "sleepd\|HKSPSleepStore\|mkcache.py" "$W/userland/build.sh" "$W/docs/STATUS-2026-11-09.md" 2>/dev/null | head -30 >> "$OUT"

e ""
e "########## 6) star jobs: is com.apple.sleepd present? ##########"
find /mnt/c/ios26 /root/star26/s94 -iname "*sleepd*" 2>/dev/null | head -10 >> "$OUT"
echo -n "s94 ramdisk has sleepd plist: " >> "$OUT"
cd "$S/tools/apfs" && python3 apfs.py tree /root/star26/s94/parts/ramdisk / 2>/dev/null | grep -ci sleepd >> "$OUT"

e ""
e "########## DONE ##########"
echo "OK $(wc -c < "$OUT") bytes"
