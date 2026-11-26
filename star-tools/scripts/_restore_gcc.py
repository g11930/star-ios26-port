#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()
# the SE5 offsets were the real clock registers all along (they read 0x80004220); keep them,
# and only the serial engine's own base moves to the one the device tree names for the touch.
for old, new in [('0x185dc', '0x185fc'), ('0x185e0', '0x18600'), ('0x185e4', '0x18604'),
                 ('0x185f4', '0x18614'), ('0x1863c', '0x1865c'), ('0x1867c', '0x1869c')]:
    s = s.replace(old, new)
# careful: 0x185fc is both the (restored) CBCR and our temporary PERF_CFG base; fix the clash
s = s.replace('GCC_QUP1_SE5_PERF_CFG(l) (gcc + 0x185fc + 4 * (l))', 'GCC_QUP1_SE5_PERF_CFG(l) (gcc + 0x1861c + 4 * (l))')
open(p, 'w').write(s)
print('gcc restored:', s.count('0x185fc'), s.count('0x1861c'))
