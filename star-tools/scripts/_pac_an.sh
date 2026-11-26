#!/bin/bash
L=/mnt/c/ios26/s62-staged.bin
echo "=== pac_emu lines ==="
strings "$L" | grep -i 'pac_emu' | head -20
echo ""
echo "=== count unhandled ==="
strings "$L" | grep -ci 'pac_emu: unhandled'
echo "=== count first-hit ==="
strings "$L" | grep -ci 'software PAuth active'
echo ""
echo "=== ESR / exception class in log ==="
strings "$L" | grep -iE 'ESR|exception|EXC_|fault|abort' | grep -viE 'cmdline|boot-args|Exception.*backtrace|user_exception_trace' | head -20
echo ""
echo "=== PAC-related external user exceptions ==="
strings "$L" | grep -iE 'user_exception|user_abort|SIGTRAP|SIGILL|SIGBUS' | head -15
echo ""
echo "=== s61d comparison: pac lines ==="
strings /mnt/c/ios26/s61d-staged.bin 2>/dev/null | grep -i 'pac_emu' | head -10
