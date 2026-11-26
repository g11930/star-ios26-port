#!/bash
L=/mnt/c/ios26/s100-live.bin
echo "===== A) oscard 相关 ====="
strings -n 6 "$L" | grep -i "oscard" | head -12
echo
echo "=== B) rootfs 里 oscard 是否存在 ==="
ls -l /root/sys-root/usr/libexec/oscard 2>/dev/null || echo "no /usr/libexec/oscard"
find /root/sys-root -maxdepth 5 -name "oscard*" 2>/dev/null | head -5
echo
echo "=== C) launchd 里 display 相关 job ==="
find /root/sys-root -maxdepth 6 -path "*LaunchDaemons*" -name "*display*" 2>/dev/null | head -5
find /root/sys-root -maxdepth 6 -path "*LaunchDaemons*" -name "*oscar*" 2>/dev/null | head -5
echo
echo "=== D) 日志里 display 服务/守护进程线索 ==="
strings -n 6 "$L" | grep -iE "displayd|DisplayServices|corebrightness|backlight" | head -12
echo "===== DONE ====="
