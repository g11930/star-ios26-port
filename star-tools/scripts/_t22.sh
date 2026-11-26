#!/bin/bash
A=/mnt/d/桌面/adb-fastboot/adb.exe
echo "=== fts probe lines ==="
timeout 90 $A shell "dmesg | grep -iE 'FTS|fts' | head -60" 2>&1 | head -62
echo "=== spi controller lines ==="
timeout 60 $A shell "dmesg | grep -iE 'spi_geni|geni_spi|spi-qup|qup' | head -20" 2>&1 | head -22