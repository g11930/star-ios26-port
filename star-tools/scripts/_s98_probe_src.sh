#!/bash
cd /root/star26/star-native || exit 1
echo "===== A) thread_dump 入口与门控 ====="
grep -rn "star_threaddump\|thread_dump\|annibale_thread\|startup_thread" --include=*.c --include=*.h bsd/dev/star osfmk/kern 2>/dev/null | grep -v "\.bak" | head -25
echo
echo "===== B) star_msgprobe.c 结构（现存挂点） ====="
sed -n '1,60p' bsd/dev/star/star_msgprobe.c 2>/dev/null
echo
echo "===== C) bsd/dev/star 目录 ====="
ls -la bsd/dev/star | head -30
echo
echo "===== DONE ====="
