#!/bin/bash
F=/root/star26/star-native/osfmk/arm64/sleh.c
echo "=== grep pac emu entry points ==="
grep -n "pac_emu\|PAC_EMU\|pac_disable\|sleh_pac" "$F" | head -30
