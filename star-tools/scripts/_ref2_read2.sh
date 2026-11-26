#!/bin/bash
# read warsaw recent status docs (bounded)
W=/root/ref2/warsaw-xnu-kernel-RedmiK90Ultra
echo "############ STATUS-2026-11-09.md (head 80) ############"
head -80 "$W/docs/STATUS-2026-11-09.md" 2>/dev/null
echo
echo "############ HANDOVER-DSH-2026-11-15.md (head 60) ############"
head -60 "$W/docs/HANDOVER-DSH-2026-11-15.md" 2>/dev/null
