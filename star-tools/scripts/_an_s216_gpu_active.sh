#!/bin/bash
L=/mnt/d/ios26/s216-mid-072141.bin
echo "=== who submits to AnnibaleGPU ==="
grep -a -oE "annibalemetal\[[a-z]+ [0-9]+\]" "$L" | sort | uniq -c | sort -rn | head -8
echo
echo "=== submit/open lines ==="
grep -a -E "AnnibaleGPU client opened|AnnibaleGPU: submit in|opens AnnibaleGPU" "$L" | head -8
echo
echo "=== render pipelines by process ==="
grep -a -oE "annibalemetal\[[a-z]+ [0-9]+\]: render pipelines: [0-9]+ built" "$L" | sort | uniq -c | sort -rn | head -6
echo
echo "=== UI milestones ==="
for k in "presentationsLock" "lock screen transition" "Unlocked since boot" "PosterBoard" "did finish launch" "scene create"; do
  printf "  %-26s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
