#!/bin/bash
echo "=== custom service-by-name helpers in the kernel ==="
grep -rn 'IOSvc\|iOSvc\|io_svc' /root/star26/star-native/iokit/Kernel/*.cpp /root/star26/star-native/iokit/Kernel/*.h 2>/dev/null | grep -i 'name\|query\|by_name' | head -10
echo
echo "=== sysctl(s) exposed for userland ==="
grep -rn 'sysctl\|SYSCTL' /root/star26/star-native/iokit/Kernel/IOUserClient.cpp | head -8
echo
echo "=== userland: any call that gets a service without a master port ==="
grep -rn 'IOServiceGetMatchingService' /root/star26/hackios-xnu-kernel/tools/userland-driver/*.inc | head -6
</bash>
