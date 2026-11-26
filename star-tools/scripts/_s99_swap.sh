#!/bash
L=/mnt/c/ios26/s99-live.bin
echo "===== A) 现有 swap/flip 埋点是否触发 ====="
for p in "tl: s " "tl: l " "P34:" "tl: c " "fbtrace"; do
  printf '%s -> ' "$p"; strings -n 4 "$L" | grep -c -F "$p"
done
echo
echo "===== B) 是否有任何 tl: 行 ====="
strings -n 4 "$L" | grep -F "tl: " | head -12
echo
echo "===== C) newUserClient 定义位置 ====="
cd /root/star26/star-native && grep -rn "newUserClient" iokit/ | head -10
echo
echo "===== D) IOMobileFramebuffer 用户客户端 open 日志 ====="
strings -n 6 "$L" | grep -iE "IOMobileFramebufferUserClient|user client|clientClose" | head -10
echo "===== DONE ====="
