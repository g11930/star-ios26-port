#!/bin/bash
cd /root/star26/star-native || { echo NO_TREE; exit 1; }
echo "=== PWD/HEAD ==="
pwd; git log --oneline -1 2>/dev/null
echo "=== exit reason string ==="
grep -rn "exited -- exit reason namespace" --include=*.c --include=*.h --include=*.cpp . | head -20
echo "=== panic_on_crash ==="
grep -rn "panic_on_crash\|PANIC_ON_CRASH\|panic-on-crash" --include=*.c --include=*.h --include=*.cpp . | head -30
echo "=== exc handler sent ==="
grep -rn "sent by exc handler" --include=*.c --include=*.h --include=*.cpp . | head -10
