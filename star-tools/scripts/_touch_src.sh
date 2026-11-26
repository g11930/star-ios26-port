#!/bin/bash
echo "=== kernel side: /dev/annibale-touch ==="
grep -rn 'annibale-touch' /root/star26/star-native/bsd /root/star26/star-native/iokit 2>/dev/null | head -10
echo "=== userland: inject_touch.inc head ==="
sed -n '1,40p' /root/star26/hackios-xnu-userland/userland/src/inject/inject_touch.inc
echo "=== reference trees present ==="
ls -d /root/star26/warsaw-ref /root/k90-src /root/g11930-ref 2>/dev/null
grep -rln 'digitizer\|IOHIDDigitizer\|touch' /root/star26/warsaw-ref 2>/dev/null | head -10
</