#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()

# star-B.dtb: the touch chip sits on spi@a8c000 (QUPv3 group 1, SE3), not SE5 at 0xa94000
s = s.replace('#define SE_PHYS                 0x00a94000UL', '#define SE_PHYS                 0x00a8c000UL')

# ... and each SE's clock registers sit 0x10 apart, two seats earlier
for old, new in [('0x185fc', '0x185dc'), ('0x18600', '0x185e0'), ('0x18604', '0x185e4'),
                 ('0x18614', '0x185f4'), ('0x1861c', '0x185fc'), ('0x1865c', '0x1863c'),
                 ('0x1869c', '0x1867c')]:
    s = s.replace(old, new)

# the panel is an ST FTS ("st,spi", st_fts_k3s.ftb), not a Goodix
s = s.replace('\ttouch_chip = touch_chip_detect();', '\ttouch_chip = TOUCH_FOCALTECH;   /* star: fts@0, compatible "st,spi" */')
open(p, 'w').write(s)
print('SE_PHYS a8c000:', '0x00a8c000UL' in s, '| forced FTS:', 'touch_chip = TOUCH_FOCALTECH;' in s)