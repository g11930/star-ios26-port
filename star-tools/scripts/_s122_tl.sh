#!/bash
L=/mnt/c/ios26/s122-live.bin
strings -n 6 "$L" > /tmp/s122.txt
echo "===== 完整时间线 ====="
grep -E "Initializing TRIClient|Received handshake request from 39|Received handshake request from" /tmp/s122.txt | cut -c1-140 | head -6
echo
echo "--- triald 最早 3 条（带时间）:"
grep "triald\[" /tmp/s122.txt | head -3 | cut -c1-140
echo
echo "--- backboardd 主线程最后一条:"
grep "backboardd\[39:280\]\|backboardd\[39:28" /tmp/s122.txt | tail -3 | cut -c1-140
echo
echo "--- launchd 03:03 段：是否有 triald 的 Doing boot task / spawn:"
grep -nE "EXECDBG: loading /usr/libexec/triald|EXECDBG: loading /annibale/bin/trialwake" /tmp/s122.txt | head -4
echo
echo "===== 首个 handshake 前 RB 是否静默（TRIClient 到首条 handshake 的跨度用时间看）====="
grep -E "runningboardd\[30:343\]" /tmp/s122.txt | tail -2 | cut -c1-140
echo "===== DONE ====="
</bash>
