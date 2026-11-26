#!/bin/bash
STAR=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
UP=/root/star26/hackios-xnu-kernel/xnu/files/bsd/dev/annibale/annibale_goodix.c
RED=/root/star26/warsaw-ref/xnu/files/bsd/dev/redwood_goodix.c
for f in "$STAR" "$UP" "$RED"; do
  echo "==================== $f ($(wc -l < "$f") lines) ===================="
  echo "--- clocks_on / QUP / GENI defines ---"
  grep -nE "clocks_on|GCC_QUP1_SE5_DFSR|GCC_QUP1_SE5_CFG|SE5_CMD|SE5_CBCR|QUP1_SE5|S_AHB_CBCR|M_AHB_CBCR|XO_HZ|GENI_VERSION|qup" "$f" | head -35
  echo
done
