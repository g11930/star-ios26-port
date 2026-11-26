#!/bash
cd /root
for s in IOMobileFramebuffer AppleIOMobileFramebuffer IOFramebuffer AppleDisplay IOMobileFramebufferUserClient disp0 IOSurfaceAccelerator IOSurfaceRoot; do
  n=$(strings -n 5 backboardd.bin | grep -c -F "$s")
  printf '%-34s %s\n' "$s" "$n"
done
echo "--- 相关字符串:"
strings -n 5 backboardd.bin | grep -E "MobileFramebuffer|IOFramebuffer|AppleDisplay" | sort -u | head -20
