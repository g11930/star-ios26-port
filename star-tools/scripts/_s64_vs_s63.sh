#!/bin/bash
echo "########## available logdumps ##########"
ls -la /mnt/c/ios26/*logdump*.bin 2>/dev/null
echo
for f in /mnt/c/ios26/s63-logdump.bin /mnt/c/ios26/s64-logdump.bin; do
  [ -f "$f" ] || continue
  echo "==================== $f ===================="
  echo -n "StartWindowServer          = "; strings -a "$f" | grep -c "StartWindowServer"
  echo -n "BKDisplayRenderOverlaySpinny = "; strings -a "$f" | grep -c "BKDisplayRenderOverlaySpinny"
  echo -n "CAWindowServerDisplay      = "; strings -a "$f" | grep -c "CAWindowServerDisplay"
  echo -n "iomfb_populate_all_display = "; strings -a "$f" | grep -c "iomfb_populate_all_display_infos"
  echo -n "MiniIOMobileFramebuffer    = "; strings -a "$f" | grep -c "MiniIOMobileFramebuffer"
  echo -n "SpringBoard heartbeat      = "; strings -a "$f" | grep -c "SpringBoard heartbeat started"
  echo -n "backboardd heartbeat       = "; strings -a "$f" | grep -c "backboardd heartbeat started"
  echo -n "annibalemetal              = "; strings -a "$f" | grep -c "annibalemetal"
  echo -n "SPWNRET (s64 probe)        = "; strings -a "$f" | grep -c "SPWNRET"
  echo -n "Early boot complete        = "; strings -a "$f" | grep -c "Early boot complete"
  echo -n "distinct backboardd pids   = "; strings -a "$f" | grep -oE "backboardd\[[0-9]+" | sort -u | tr '\n' ' '
  echo
  echo -n "distinct SpringBoard pids  = "; strings -a "$f" | grep -oE "SpringBoard\[[0-9]+" | sort -u | tr '\n' ' '
  echo
  echo "-- cmdline --"
  strings -a "$f" | grep "^cmdline:" | head -3
  echo "-- spinny lines --"
  strings -a "$f" | grep "BKDisplayRenderOverlaySpinny" | head -8
  echo
done
