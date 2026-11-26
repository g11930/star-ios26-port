#!/bin/bash
R=/root/star26/star-native
echo "=== gGPUStub assignments ==="
grep -rn "gGPUStub" "$R" --include=*.cpp --include=*.c --include=*.inc --include=*.h 2>/dev/null | grep -v "\.bak"
echo
echo "=== AnnibaleGPUStartStub ==="
grep -rn "AnnibaleGPUStartStub\|StartStub" "$R" --include=*.cpp --include=*.c 2>/dev/null | grep -v "\.bak" | head
