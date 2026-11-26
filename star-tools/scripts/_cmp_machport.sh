#!/bin/bash
echo "========== star-native (current s61d) mach_port.c 2955-3010 =========="
sed -n '2955,3010p' /root/star26/star-native/osfmk/ipc/mach_port.c
echo ""
echo "========== annibale baseline (P29 kernel) same func =========="
grep -n 'mach_port_is_connection_for_service' /root/star26/hackios-xnu-kernel/xnu/files/osfmk/ipc/mach_port.c | head -3
A=$(grep -n '^mach_port_is_connection_for_service' /root/star26/hackios-xnu-kernel/xnu/files/osfmk/ipc/mach_port.c | head -1 | cut -d: -f1)
if [ -z "$A" ]; then A=$(grep -n 'mach_port_is_connection_for_service(' /root/star26/hackios-xnu-kernel/xnu/files/osfmk/ipc/mach_port.c | tail -1 | cut -d: -f1); fi
echo "annibale func line: $A"
sed -n "$((A-5)),$((A+55))p" /root/star26/hackios-xnu-kernel/xnu/files/osfmk/ipc/mach_port.c
