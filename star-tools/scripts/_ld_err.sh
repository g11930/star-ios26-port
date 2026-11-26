#!/bin/bash
L=/mnt/c/ios26/star-native-build.log
echo "=== lines with 'undefined' / 'Undefined' ==="
grep -n -i 'undefined' $L | head -20
echo
echo "=== last LD section ==="
awk '/LD mach.release.bcm2837.unstripped.noctf/{f=1} f' $L | head -40
