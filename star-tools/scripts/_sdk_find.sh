#!/bin/bash
for base in /root/star26/warsaw-ref/xnu-deps /root/star26/hackios-xnu-kernel/xnu-deps; do
  echo "=== $base ==="
  ls -la "$base" 2>/dev/null | head -12
  find "$base" -maxdepth 4 \( -type d -o -type l \) -name "iPhoneOS.sdk" 2>/dev/null | head -5
done
echo "=== sdk header corefoundation candidates ==="
find /root/star26 -path "*/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" 2>/dev/null | head -8
