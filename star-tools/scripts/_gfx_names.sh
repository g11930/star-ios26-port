#!/bash
cd /root || exit 1
echo "===== backboardd 里的图形服务名出现次数 ====="
for k in AppleDisplay IOGPU AGX AppleCLCD IOAccelerator IOMobileFramebuffer IOSurface displaypipeline DCP; do
  n=$(strings -n 6 backboardd.bin | grep -c -F "$k")
  printf '%-22s %s\n' "$k" "$n"
done
echo
echo "===== SpringBoard 里的图形服务名 ====="
SB=/root/sys-root/System/Library/CoreServices/SpringBoard.app/SpringBoard
for k in AppleDisplay IOMobileFramebuffer AppleM2CLCD; do
  n=$(strings -n 6 "$SB" | grep -c -F "$k")
  printf '%-22s %s\n' "$k" "$n"
done
echo "===== DONE ====="
</bash>
