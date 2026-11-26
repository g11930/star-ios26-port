#!/bin/bash
R=/root/micode-star
echo "--- tree depth ---"
ls $R | head -20
echo "--- search gcc-lahaina anywhere ---"
find $R -name 'gcc-lahaina*' 2>/dev/null | head -5
echo "--- search spi-geni ---"
find $R -name 'spi-geni*' 2>/dev/null | head -5
echo "--- touch dirs ---"
find $R -type d -name 'touchscreen' 2>/dev/null | head -5
</