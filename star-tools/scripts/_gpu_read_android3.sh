#!/bin/bash
A=/d/桌面/adb-fastboot/adb.exe
S() { MSYS_NO_PATHCONV=1 "$A" shell "su -c '$1'" 2>&1 | tr -d '\r'; }

echo "----- find kgsl dt node -----"
S 'ls -d /proc/device-tree/soc/*kgsl* /proc/device-tree/*kgsl* 2>/dev/null'
echo
echo "----- node children -----"
S 'N=$(ls -d /proc/device-tree/soc/*kgsl* 2>/dev/null | head -1); echo NODE=$N; ls "$N"'
echo
echo "----- pwrlevels within node -----"
S 'N=$(ls -d /proc/device-tree/soc/*kgsl* 2>/dev/null | head -1); P="$N/qcom,gpu-pwrlevels"; ls "$P"; for d in "$P"/*; do printf "%s " "$d"; for k in qcom,gpu-freq qcom,level qcom,voltage; do printf "%s=" "$k"; od -An -tx4 -v "$d/$k" 2>/dev/null | tr -d "\n "; printf " "; done; echo; done'
echo
echo "----- bus freq / bw props in node -----"
S 'N=$(ls -d /proc/device-tree/soc/*kgsl* 2>/dev/null | head -1); for k in qcom,bus-freq qcom,bus-max qcom,bus-min qcom,initial-pwrlevel qcom,bus-width qcom,gpu-bwlevel qcom,ca-target-pwrlevel qcom,idle-timeout qcom,strtstp-sleepwake qcom,gpu-quirk-secpage-faults; do [ -e "$N/$k" ] && { printf "%s: " "$k"; od -An -tx4 -v "$N/$k" | tr -d "\n"; echo; }; done; ls "$N" | head -60'
echo
echo "----- dmesg (root) kgsl/adreno -----"
S 'dmesg | grep -i -E "kgsl|adreno" | tail -45'
