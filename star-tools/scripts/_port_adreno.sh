#!/bin/bash
# Port the SM8350 Adreno driver from the public star repo into star-native as bsd/dev/star/annibale_adreno.c
set -e
SRC=/root/g11930-ref/xnu/files/bsd/dev/redwood_adreno.c
DST=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
CONF=/root/star26/star-native/bsd/conf/files

cp -f $CONF $CONF.pre-gpu-port

# 1) copy + rename the API, and point the header at ours
sed -e 's/redwood_input\.h/annibale_input.h/g' \
    -e 's/\bredwood_/annibale_/g' \
    -e 's/\bRedwood/Annibale/g' \
    $SRC > $DST

# 2) what symbols it provides vs what our header asks for
echo "=== provided (non-static definitions) ==="
grep -oE '^[a-z_0-9]+ \*?annibale_[a-z_0-9]*|^annibale_[a-z_0-9]+' $DST | tr -d '*' | sort -u | head -30

echo "=== our header asks for ==="
grep -oE 'annibale_gpu_[a-z_0-9]+' /root/star26/star-native/bsd/sys/annibale_input.h | sort -u

# 3) wire it into the build next to the other star drivers
grep -q 'annibale_adreno.c' $CONF || sed -i '111i bsd/dev/star/annibale_adreno.c		standard' $CONF

grep -n 'annibale_adreno' $CONF
wc -l $DST
</bash>
