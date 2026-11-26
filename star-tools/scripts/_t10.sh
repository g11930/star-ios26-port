#!/bin/bash
echo "=== reference docs touch ==="
grep -rn -i 'touch\|focaltech\|0x56\|spi' /root/g11930-ref/docs/*.md 2>/dev/null | head -20
echo "=== project docs ==="
ls /mnt/d/桌面/star26-deps/*.md 2>/dev/null | head
grep -rn -i '触摸\|touch\|focaltech' /mnt/d/桌面/star26-deps/*.md 2>/dev/null | head -15