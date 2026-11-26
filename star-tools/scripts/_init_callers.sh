#!/bin/bash
cd /root/star26/star-native
echo "--- definitions ---"
grep -rn 'annibale_goodix_init' --include=*.c --include=*.cpp --include=*.h . | grep -v BUILD | head
echo "--- call site in input.c ---"
grep -n 'annibale_goodix_init' bsd/dev/star/annibale_input.c
echo "--- is input init called from anywhere ---"
grep -rn 'annibale_input_init' --include=*.c --include=*.cpp --include=*.h . | grep -v BUILD | head
</>
