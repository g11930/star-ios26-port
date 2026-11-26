#!/bin/bash
for f in /root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib.v013 \
         /root/star26/p20/work/root/lib/libannibalemetal.dylib \
         /root/star26/p18/work/root/lib/libannibalemetal.dylib \
         /root/star26/p2/work/root/lib/libannibalemetal.dylib ; do
  echo "== $f"
  ls -la "$f" 2>/dev/null
  file "$f" 2>/dev/null
  md5sum "$f" 2>/dev/null
done
echo "=== original inside the release tarball ==="
tar tzf /root/star26/release/hackios-k90-v0.1.3.tar.gz | grep -i 'annibalemetal' | head
