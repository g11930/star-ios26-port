#!/bin/bash
# search annibale + warsaw docs for our boot-stall symptoms
A=/root/ref2/hackios-redmi-k90-annibale
W=/root/ref2/warsaw-xnu-kernel-RedmiK90Ultra
echo "===== A. annibale docs: 98 / 进度条 / 卡 / stall ====="
grep -rn --include='*.md' -i -E '98%|进度条|progress bar|卡在|卡死|stall|stuck' \
    "$A/docs" 2>/dev/null | grep -v -i 'thermal\|fps\|帧率' | head -30
echo
echo "===== B. annibale docs: launchd / mach_msg / IPC / queue full ====="
grep -rn --include='*.md' -i -E 'mach_msg|ipc_mqueue|队列满|queue.full|IPC.*dead|launchd.*(卡|stuck|wait|hang)|launchd.*IPC' \
    "$A/docs" 2>/dev/null | head -30
echo
echo "===== C. annibale docs: checkin / bootstrap / service port ====="
grep -rn --include='*.md' -i -E 'check-?in|bootstrap|service.port|persistent services|11600|0x2d5' \
    "$A/docs" 2>/dev/null | head -20
echo
echo "===== D. warsaw docs: 同类关键词 ====="
grep -rn --include='*.md' -i -E '98%|进度条|mach_msg|queue.full|队列满|launchd.*(卡|stuck|hang|wait)' \
    "$W/docs" 2>/dev/null | head -30
echo
echo "===== E. annibale kernel tree check ====="
ls -la "$A/hackios-xnu-kernel/" 2>&1 | head -10
echo
echo "===== F. annibale userland top ====="
ls "$A/hackios-xnu-userland/" 2>/dev/null | head -20
