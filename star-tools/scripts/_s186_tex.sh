#!/bin/bash
echo "=== texture-related lines ==="
grep -a -iE 'texture.*(refus|fail|nil)|refused: |newTextureWith' /tmp/s186a.txt | sed -E 's/^/  /' | head -20
echo "=== counts of key messages ==="
for k in 'newTextureWithBytesNoCopy' 'refused' 'IOSurface' 'pixel format' 'unsupported'; do
  echo "$k: $(grep -aic "$k" /tmp/s186a.txt)"
done
echo "=== any lines with 'texture' (sample) ==="
grep -a -i 'texture' /tmp/s186a.txt | grep -v 'render pipelines' | head -12