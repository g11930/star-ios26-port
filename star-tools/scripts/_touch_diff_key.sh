#!/bin/bash
# Compare the WORKING g11930 redwood_goodix.c (saved in WSL by previous grep) vs star's.
# We saved the GitHub file via the tool into a temp; check both locations.
G=/tmp/g11930_redwood_goodix.c
S=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
if [ ! -f "$G" ]; then echo "G11930 SOURCE NOT ON DISK YET"; exit 1; fi
echo "=== key define diff ==="
for f in "$G" "$S"; do
  echo "########## $f ($(wc -l < "$f") lines)"
  grep -nE "#define (SE_PHYS|GCC_PHYS|CMD_DB_PHYS|RSC_PHYS|PIN_MISO|PIN_MOSI|PIN_CLK|PIN_CS|PIN_INT|PIN_RESET|PIN_AVDD|PIN_FUNCTION_SPI|VOTE_QUP1_SE5|FOCALTECH|GITHUB)" "$f" | head -25
done
echo
echo "=== focaltech probe present? ==="
for f in "$G" "$S"; do echo "$f: focaltech_probe=$(grep -c focaltech_probe "$f") write_pram=$(grep -c write_pram "$f") FOCALTECH_FW_LENGTH=$(grep -c FOCALTECH_FW_LENGTH "$f")"; done
