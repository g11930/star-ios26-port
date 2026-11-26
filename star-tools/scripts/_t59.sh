#!/bin/bash
grep -rn 'not a platform binary' /root/star26/star-native 2>/dev/null | head -8
echo ---
grep -rn 'platform binary' /root/star26/star-native/bsd 2>/dev/null | head -10