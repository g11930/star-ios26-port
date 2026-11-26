#!/bash
cd /root/star26/star-native || exit 1
echo "===== matching 相关入口 ====="
grep -n "get_matching_service\|get_matching_services\|copyMatchingService\|getMatchingServices" iokit/Kernel/IOUserClient.cpp | head -25
echo
echo "===== is_io_service_get_matching_service_bin 片段 ====="
grep -n -A 25 "is_io_service_get_matching_service_bin" iokit/Kernel/IOUserClient.cpp | head -40
