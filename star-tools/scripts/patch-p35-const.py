#!/usr/bin/env python3
"""P35: the P34 probe without a new boot-arg tunable.

P34 panicked at startup in kalloc_type_validate_flags() with an empty kext name, and the only
structural change it made was one more TUNABLE: SECURITY_READ_ONLY_LATE puts it in the KLD's
__const section, which grew by 32 bytes (0x3868 -> 0x3888). This build keeps the sampling and
drops the extra tunable, so the section layout is the one P33 ran with.
"""
import sys

SRC = "/root/star26/kbuild/xnu-12377.121.6/iokit/Kernel/MiniIOMobileFramebuffer.cpp"

with open(SRC) as f:
    text = f.read()

decl = 'static TUNABLE(uint32_t, gProbe, "fbprobe", 0);'
if decl in text:
    text = text.replace(decl, '/* P35: sampling is always on; one boot-arg less, one section entry less. */\n'
                              'static const int gProbe = 1;', 1)
    print("tunable replaced by a constant")
else:
    print("no tunable to replace")

with open(SRC, "w") as f:
    f.write(text)

print("gProbe uses:", text.count("gProbe"))
print("fbprobe left:", text.count("fbprobe"))
