#!/bin/bash
# Confirm the rebuilt, signed driver library is the one that went into root.apfs.
S=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
N=/root/star26/p22/libannibalemetal.dylib
echo "=== staging ==="
ls -la "$S"
md5sum "$S"
echo "=== rebuilt ==="
ls -la "$N"
md5sum "$N"
echo "=== fallback path present in staging? ==="
grep -c 'client-memory copy allocation failed' "$S"
echo "=== root.apfs build time vs staging ==="
ls -la --time-style=full-iso /root/star26/p22/root.apfs "$S"
