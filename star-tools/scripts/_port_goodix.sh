#!/bin/bash
set -e
R=/root/g11930-ref/xnu/files/bsd/dev
K=/root/star26/star-native/bsd/dev/star

cp $R/redwood_goodix.c $K/annibale_goodix.c
cp $R/redwood_focaltech_fw.h $K/annibale_focaltech_fw.h

python3 - <<'PY'
import re
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()
s = s.replace('redwood_focaltech_fw.h', 'annibale_focaltech_fw.h')
s = s.replace('redwood_focaltech_fw', 'annibale_focaltech_fw')
s = s.replace('redwood_goodix_init', 'annibale_goodix_init')
s = s.replace('redwood_touch_post', 'annibale_touch_post')
s = s.replace('redwood_tl', 'annibale_tl')
s = s.replace('redwood_cpufreq_touch', 'annibale_cpufreq_touch')
s = s.replace('<sys/redwood_input.h>', '<sys/annibale_input.h>')
s = s.replace('redwood_', 'annibale_').replace('REDWOOD_', 'ANNIBALE_')
open(p, 'w').write(s)
print('renamed; remaining redwood refs:', s.count('redwood'))
PY

grep -q 'annibale_goodix.c' /root/star26/star-native/bsd/conf/files || \
  sed -i 's#^bsd/dev/star/annibale_image.c\t\tstandard$#bsd/dev/star/annibale_goodix.c\tstandard\nbsd/dev/star/annibale_image.c\t\tstandard#' /root/star26/star-native/bsd/conf/files

grep -n 'annibale_goodix' /root/star26/star-native/bsd/conf/files
</>
