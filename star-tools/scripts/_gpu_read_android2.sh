#!/bin/bash
A=/d/桌面/adb-fastboot/adb.exe
dump() { echo "----- $1 -----"; MSYS_NO_PATHCONV=1 "$A" shell "$2" 2>&1 | tr -d '\r'; echo; }

dump "pwrlevel scalars" 'for f in num_pwrlevels max_pwrlevel min_pwrlevel default_pwrlevel thermal_pwrlevel freq_table_mhz min_clock_mhz max_clock_mhz; do printf "%s=" $f; cat /sys/class/kgsl/kgsl-3d0/$f 2>/dev/null; echo; done'
dump "pwrlevels dt dir" 'ls /proc/device-tree/qcom,gpu-pwrlevels/ 2>&1'
dump "pwrlevels dt values" 'for d in /proc/device-tree/qcom,gpu-pwrlevels/*; do printf "%s freq=" "$d"; od -An -tx4 -v "$d/qcom,gpu-freq" 2>/dev/null | tr -d "\n"; printf " level="; od -An -tx4 -v "$d/qcom,level" 2>/dev/null | tr -d "\n"; printf " volt="; od -An -tx4 -v "$d/qcom,voltage" 2>/dev/null | tr -d "\n"; echo; done'
dump "gpu dt props" 'for f in /proc/device-tree/qcom,gpu-pwrlevel-bins* /proc/device-tree/qcom,initial-pwrlevel /proc/device-tree/qcom,bus-width /proc/device-tree/qcom,gpu-model /proc/device-tree/qcom,chip-id; do [ -e "$f" ] && { printf "%s: " "$f"; od -An -tx4 -v "$f" | tr -d "\n"; echo; }; done'
dump "kgsl busmon freqs" 'cat /sys/class/devfreq/kgsl-busmon/available_frequencies 2>/dev/null; echo; cat /sys/class/devfreq/kgsl-busmon/cur_freq 2>/dev/null'
dump "kgsl devfreq freqs" 'cat /sys/class/devfreq/3d00000.qcom,kgsl-3d0/available_frequencies 2>/dev/null; cat /sys/class/devfreq/3d00000.qcom,kgsl-3d0/governor 2>/dev/null'
dump "bus_split / minbw" 'for f in bus_split minbw_timer idle_timer wake_timeout usesgmem gpu_llc_slice_enable acd ifpc popp; do printf "%s=" $f; cat /sys/class/kgsl/kgsl-3d0/$f 2>/dev/null; echo; done'
dump "dmesg kgsl" 'dmesg 2>/dev/null | grep -i -E "kgsl|adreno|gpu" | tail -40 || echo "dmesg denied"'
dump "root check" 'id; su -c "id" 2>&1 | head -2'
