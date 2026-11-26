#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib.s213-pre
echo "=== 历史 dylib (当前 s212 镜像用的) unlock 痕迹 ==="
for s in '_appearState' 'waiting for CoverSheet' 'layout element' 'com.apple.lock-screen' 'displayLayoutPublisher' 'SBCoverSheetPresentationManager' 'unlockUIFromSource'; do
  echo "  [$(strings "$D" | grep -Fc "$s")] $s"
done
echo "=== 历史 dylib build 痕迹 ==="
strings "$D" | grep -iE 'clang version|/usr/bin|isysroot' | head -5
echo "=== source 24 vs 25: 反汇编 unlockUIFromSource 附近立即数 ==="
python3 - "$D" <<'PY'
import subprocess,sys
p=sys.argv[1]
# find sel_registerName("unlockUIFromSource:withOptions:") then the msgSend with immediate 24/25
# simpler: dump disasm and look for "mov x?, #0x18" (24) or "#0x19" (25) near unlock strings
out=subprocess.run(['llvm-objdump','-d','--macho',p],capture_output=True,text=True).stdout
lines=out.splitlines()
for i,l in enumerate(lines):
    if '#0x18' in l or '#0x19' in l:
        ctx=' | '.join(x.strip() for x in lines[max(0,i-2):i+2])
        print(ctx[:200])
PY
