#!/bin/bash
echo "=== proof npz count ==="
if [ -d /root/dsc26_proof ]; then
  ls /root/dsc26_proof/*.npz 2>/dev/null | wc -l
  if [ -f /root/dsc26_proof/summary.json ]; then
    echo "SUMMARY_READY"
  fi
else
  echo "NO_PROOF_DIR"
fi
echo "=== ipsw files ==="
find /root -maxdepth 5 -iname '*.ipsw' -printf '%p %s\n' 2>/dev/null | head -30
echo "=== trust cache im4p ==="
find /root -maxdepth 7 \( -iname '*trustcache*' -o -iname 'trst*' -o -iname 'trcs*' \) -printf '%p %s\n' 2>/dev/null | head -50
echo "=== star26 ipsw dir ==="
ls -la /root/star26/ipsw/ 2>/dev/null | head -60
