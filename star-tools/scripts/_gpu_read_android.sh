#!/bin/bash
# Wait for the phone to show up on adb, then dump the GPU facts we need.
A=/d/桌面/adb-fastboot/adb.exe
OUT=/d/桌面/star26-deps/gpu-facts
mkdir -p "$OUT"

echo "=== waiting for adb device (up to 180s) ==="
for i in $(seq 1 60); do
  D=$(MSYS_NO_PATHCONV=1 "$A" devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}' | head -1)
  if [ -n "$D" ]; then echo "device: $D after ${i}0s"; break; fi
  sleep 3
done
if [ -z "$D" ]; then
  echo "NO ADB DEVICE. current state:"
  MSYS_NO_PATHCONV=1 "$A" devices 2>&1
  exit 1
fi

dump() {
  name="$1"; shift
  echo "----- $name -----"
  MSYS_NO_PATHCONV=1 "$A" shell "$@" 2>&1 | tr -d '\r'
  echo
}

{
echo "################ GPU FACTS $(date)"
dump "gpu_model"            'cat /sys/class/kgsl/kgsl-3d0/gpu_model'
dump "gpu_available_frequencies" 'cat /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies'
dump "devfreq_available_frequencies" 'cat /sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies'
dump "devfreq_governor"     'cat /sys/class/kgsl/kgsl-3d0/devfreq/governor'
dump "devfreq_cur_freq"     'cat /sys/class/kgsl/kgsl-3d0/devfreq/cur_freq'
dump "gpu_clock_mhz"        'cat /sys/class/kgsl/kgsl-3d0/gpu_clock_stats 2>/dev/null; cat /sys/class/kgsl/kgsl-3d0/clock_mhz 2>/dev/null'
dump "gpu_busy"             'cat /sys/class/kgsl/kgsl-3d0/gpu_busy_percentage 2>/dev/null'
dump "gpu_pwrscale"         'ls /sys/class/kgsl/kgsl-3d0/'
dump "gpu_pwrlevels_dt(binary hex)" 'od -An -tx4 -v /proc/device-tree/qcom,gpu-pwrlevels/@0/qcom,gpu-freq 2>/dev/null; echo ---level---; od -An -tx4 -v /proc/device-tree/qcom,gpu-pwrlevels/@0/qcom,level 2>/dev/null'
dump "gpu_pwrlevels_all"    'for d in /proc/device-tree/qcom,gpu-pwrlevels/@*; do echo "$d"; od -An -tx4 -v "$d/qcom,gpu-freq" 2>/dev/null; od -An -tx4 -v "$d/qcom,level" 2>/dev/null; od -An -tx4 -v "$d/qcom,voltage" 2>/dev/null; done'
dump "gpu_bw_dt"            'for f in /proc/device-tree/qcom,gpu-bwlevel* /proc/device-tree/qcom,initial-pwrlevel /proc/device-tree/qcom,bus-width; do echo "$f"; od -An -tx4 -v "$f" 2>/dev/null; done'
dump "ddr_bwmon"            'ls /sys/class/devfreq/ 2>/dev/null; cat /sys/class/devfreq/*/available_frequencies 2>/dev/null | head -5'
dump "cmd_db_bus"           'ls /sys/kernel/debug/rpmh* 2>/dev/null; cat /sys/kernel/debug/rpmh/resource_stats 2>/dev/null | head -40'
dump "chip_id"              'cat /sys/class/kgsl/kgsl-3d0/chipid 2>/dev/null; cat /proc/device-tree/qcom,chipid 2>/dev/null | od -An -tx4'
} | tee "$OUT/gpu-facts-$(date +%H%M%S).txt"

echo
echo "=== saved under $OUT ==="
ls -la "$OUT"
