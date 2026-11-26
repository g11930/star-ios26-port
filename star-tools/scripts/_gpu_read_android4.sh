#!/bin/bash
A=/d/桌面/adb-fastboot/adb.exe
S() { MSYS_NO_PATHCONV=1 "$A" shell "su -c '$1'" 2>&1 | tr -d '\r'; }
N=/proc/device-tree/soc/qcom,kgsl-3d0@3d00000

echo "----- node listing -----"
S "ls $N"
echo
echo "----- pwrlevels (freq / level / voltage) -----"
S "P=$N/qcom,gpu-pwrlevels; ls \$P; for d in \$P/*; do printf '%s ' \"\$d\"; for k in qcom,gpu-freq qcom,level qcom,voltage; do printf '%s=' \"\$k\"; od -An -tx4 -v \"\$d/\$k\" 2>/dev/null | tr -d '\n '; printf ' '; done; echo; done"
echo
echo "----- other gpu props -----"
S "N=$N; for k in qcom,bus-freq qcom,bus-max qcom,bus-min qcom,initial-pwrlevel qcom,bus-width qcom,idle-timeout qcom,gpu-model qcom,chipid qcom,gpu-quirk-secpage-faults qcom,acd-level qcom,pm-qos-latency; do [ -e \"\$N/\$k\" ] && { printf '%s: ' \"\$k\"; od -An -tx4 -v \"\$N/\$k\" | tr -d '\n'; echo; }; done"
echo
echo "----- kgsl-ddr-qos node -----"
S "ls /proc/device-tree/soc/qcom,kgsl-ddr-qos; for k in /proc/device-tree/soc/qcom,kgsl-ddr-qos/*; do printf '%s: ' \"\$k\"; od -An -tx4 -v \"\$k\" 2>/dev/null | tr -d '\n'; echo; done"
echo
echo "----- kernel log via logcat -----"
S "logcat -b kernel -d 2>/dev/null | grep -i -E 'kgsl|adreno|gpu' | tail -30"
