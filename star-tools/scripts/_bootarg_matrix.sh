#!/bin/bash
OUT=/mnt/c/ios26/bootarg_matrix.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
K=/root/star26/star-native
B=/mnt/c/ios26/s94-boot.img

e "=== K90 README v92 cmdline block (lines 45-60) ==="
sed -n '45,60p' /root/star26/warsaw-ref/README.md >> "$OUT"

e ""
e "=== star kernel: which of these boot-args have a parser? ==="
for arg in metal metal_profile fb_hz fb_ca_hz touch_poll_us touch_lat cpufreq cpufreq_mhz wifi bt pcie autounlock applog rwa_software ufs ufs_native ufs_write launchd_unsecure_cache small_cores_after bootcpu cpus panic_on_crash_disabled; do
  n=$(grep -rl "PE_parse_boot_argn(\"$arg\"\|PE_parse_boot_arg(\"$arg\"" "$K/bsd" "$K/osfmk" "$K/iokit" 2>/dev/null | wc -l)
  e "  %-26s parser_files=%s" "$arg" "$n"
done

e ""
e "=== star s94 cmdline currently has: ==="
tr -d '\0' < /root/star26/s94/parts/cmdline | tr ' ' '\n' | grep '=' >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
