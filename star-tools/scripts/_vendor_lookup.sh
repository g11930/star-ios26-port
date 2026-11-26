#!/bin/bash
R=/root/micode-star
echo "--- gcc driver files ---"
find $R -name 'gcc-lahaina*.c' 2>/dev/null | head -3
echo "--- clock id 0x6a ---"
grep -rn 'QUP1_SE[0-9]_CBCR\|QUP1_SE[0-9]_CMD_RCGR' $R/drivers/clk/qcom/gcc-lahaina.c 2>/dev/null | head -8
echo "--- spi geni regs: SE_DMA / GENI offsets ---"
grep -rn 'define SE_GENI\|GENI_FW_REVISION\|SE_GENI_STATUS' $R/drivers/spi/spi-geni-qcom.c 2>/dev/null | head -8
echo "--- fts driver present? ---"
ls $R/drivers/input/touchscreen/ 2>/dev/null | grep -i 'fts\|focal\|st_' | head -6
</