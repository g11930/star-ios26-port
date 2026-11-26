#!/bin/bash
ls /root/xnu26-test/bin 2>/dev/null | head -20
which mkbootimg 2>/dev/null || echo "no mkbootimg"
find / -maxdepth 4 -name 'mkbootimg*' -not -path '*/proc/*' 2>/dev/null | head -5
python3 -c "import sys; print('python', sys.version)"