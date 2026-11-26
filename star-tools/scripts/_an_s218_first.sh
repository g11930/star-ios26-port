#!/bin/bash
L=/mnt/d/ios26/now-075648.bin
echo "===== [1] 调频日志（speed is now / speed vote / GPU at）====="
grep -a -E "the GPU.s speed is now|speed vote for|GPU at [0-9]+ MHz|speed changes since" "$L" | tail -20
echo
echo "===== [2] 启动期 GPU 10 档与初始投票 ====="
grep -a -E "10 speeds, 315|the speed wanted:|GMU accepts the speed" "$L" | tail -6
echo
echo "===== [3] 错误信号 ====="
for k in PANIC "panic:" "kernel panic" "SMMU" "fault" "not acknowledged"; do
    printf "%-22s %s\n" "$k" "$(grep -a -i -c "$k" "$L")"
done
echo
echo "===== [4] 温度读取（若有）====="
grep -a -i "sensors read\|degrees" "$L" | tail -3
echo
echo "===== [5] 日志规模/最新时间 ====="
wc -l "$L"; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -3
