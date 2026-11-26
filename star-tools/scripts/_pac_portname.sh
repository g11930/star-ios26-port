#!/bin/bash
echo "########## 1. launchd 二进制的 ABI 子类型 ##########"
wsl.exe -d Ubuntu-24.04 bash -lc 'python3 - <<PY
import struct
p="/root/star26/p3/pacscan/sbin/launchd"
d=open(p,"rb").read(32)
magic,cputype,cpusub,ft,ncmds,sz,flags,_=struct.unpack("<IiiIIIII",d)
print("launchd cputype=%#x cpusubtype=%#x (ARM64E_PTRAUTH ABI bit=0x80000000)"%(cputype&0xffffffff,cpusub&0xffffffff))
PY' 2>/dev/null
echo
echo "########## 2. 我们 PAC 仿真代码位置 ##########"
grep -rln "pac_emu\|pacemu\|ptrauth.*emul\|FEAT_PAuth\|software.*PAC" /root/star26/star-native/osfmk/ 2>/dev/null | head -20
echo
echo "########## 3. PAC 仿真对 syscall 参数/寄存器的处理 ##########"
grep -rnE "pac_emu|authenticate|auth.*pointer|xpaci|autia|braa|blraa|retaa" /root/star26/star-native/osfmk/arm64/*.c /root/star26/star-native/osfmk/arm64/*.s 2>/dev/null | head -40
echo
echo "########## 4. mach_msg trap 入口是否有 PAC strip ##########"
grep -rnE "mach_msg|ptrauth_strip|xpaci|strip.*pac|untag" /root/star26/star-native/osfmk/arm64/trap.c /root/star26/star-native/bsd/kern/syscalls.master 2>/dev/null | head -30
