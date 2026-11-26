#!/bin/bash
R=/root/g11930-ref/xnu/files/bsd/dev/redwood_goodix.c
O=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "=== ours clocks_on ==="
awk '/^clocks_on\(void\)/,/^}/' $O
echo "=== ref clocks_on ==="
awk '/^clocks_on\(void\)/,/^}/' $R