#!/bin/bash
SR=/root/star26/star-native
echo "=== vm_shared_region.c: small-pages / part_v5 symbols ==="
grep -nE 'slide_part_v5|slide_page_v5|PAGE_SIZE_FOR_SR_SLIDE|part_starts|page_size.*PAGE_SIZE|slide_info_page_size' "$SR/osfmk/vm/vm_shared_region.c" | head -40
echo "=== vm_shared_region_pager.c: part handling ==="
grep -nE 'part_starts|slide_part|part_size|srp_part|SLIDE_V5|page_size' "$SR/osfmk/vm/vm_shared_region_pager.c" | head -40
echo "=== slide_page_v5 function presence (nm on built kernel if available) ==="
ls -la /root/star26/star-native/*.noctf 2>/dev/null | head
echo "=== check 4k shared region patch markers ==="
grep -rnE 'native-4k-shared-region|4KB|4KiB|page_size > PAGE_SIZE|SLIDE_PAGE_SIZE_16KB' "$SR/osfmk/vm/vm_shared_region.c" "$SR/osfmk/vm/vm_shared_region_pager.c" | head -40
