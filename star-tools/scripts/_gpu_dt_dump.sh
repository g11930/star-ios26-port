#!/system/bin/sh
N=/proc/device-tree/soc/qcom,kgsl-3d0@3d00000
echo "===== bins ====="
ls "$N/qcom,gpu-pwrlevel-bins"
for b in "$N"/qcom,gpu-pwrlevel-bins/*; do
  echo "--- bin: $b"
  ls "$b"
  for p in "$b"/*; do
    echo "  == $p"
    ls "$p"
    for k in qcom,gpu-freq qcom,level qcom,voltage; do
      if [ -e "$p/$k" ]; then
        echo -n "     $k = "
        od -An -tx4 -v "$p/$k" | tr '\n' ' '
        echo
      fi
    done
  done
done
echo
echo "===== bus tables ====="
for t in qcom,bus-table-ddr7 qcom,bus-table-ddr8 qcom,bus-table-cnoc qcom,l3-pwrlevels; do
  if [ -e "$N/$t" ]; then
    echo "--- $t"
    od -An -tx4 -v "$N/$t"
  fi
done
echo
echo "===== interconnect names ====="
if [ -e "$N/interconnect-names" ]; then cat "$N/interconnect-names" | tr '\0' '\n'; fi
echo
echo "===== interconnects cells ====="
if [ -e "$N/interconnects" ]; then od -An -tx4 -v "$N/interconnects"; fi
echo
echo "===== misc ====="
for k in qcom,ubwc-mode qcom,highest-bank-bit qcom,min-access-length qcom,no-nap qcom,tzone-names; do
  if [ -e "$N/$k" ]; then echo -n "$k = "; od -An -tx4 -v "$N/$k" | tr '\n' ' '; echo; fi
done
