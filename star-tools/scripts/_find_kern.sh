#!/bin/bash
R=/root/star26/star-native
echo "=== kernel artifacts ==="
find "$R/BUILD" -maxdepth 4 -name "kernel*" -o -maxdepth 4 -name "*.noctf" 2>/dev/null | head -20
echo "=== all large files ==="
find "$R/BUILD" -type f -size +8M 2>/dev/null -exec ls -l {} \; | head -10
echo "=== s198parts ==="
ls -l /root/star26/baseline/s198parts/ 2>/dev/null
