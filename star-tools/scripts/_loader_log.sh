#!/bin/bash
cd /root/star26/star-native
echo "--- loader checkpoint / log API ---"
grep -rn 'loader_checkpoint\|loader_log' --include=*.h --include=*.c osfmk bsd | grep -v BUILD | head -10
echo
echo "--- definition body ---"
grep -rn -A12 'void\s*loader_checkpoint' --include=*.c osfmk bsd | grep -v BUILD | head -25
</