#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
echo "--- physical bases ---"
grep -n '#define\s\+\(TLMM\|GCC\|SE\|RSC\|CMD_DB\)_PHYS' $F
echo "--- chip discriminator ---"
grep -n -B4 -A12 'selected goodix' $F | head -40
echo "--- gcc clock regs used ---"
grep -n '#define GCC_QUP' $F | head -12
</>
