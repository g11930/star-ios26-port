#!/bash
R=/root/sys-root
echo "===== IOMobileFramebuffer 框架文件 ====="
find $R -maxdepth 6 -iname "*IOMobileFramebuffer*" 2>/dev/null | head -10
echo
echo "===== 私有框架目录中的显示相关项 ====="
ls $R/System/Library/PrivateFrameworks 2>/dev/null | grep -iE "mobileframe|graphic|display|iosurface|backboard|skylight" | head -20
echo
echo "===== dyld cache 中的 CLCD 类名计数 ====="
for f in $R/System/Cryptexes/OS/System/Library/Caches/com.apple.dyld/dyld_shared_cache_arm64*; do
  if [ -f "$f" ]; then
    echo "-- $(basename $f)"
    printf 'AppleM2CLCD %s\n' "$(grep -c -a 'AppleM2CLCD' "$f")"
    printf 'AppleH1CLCD %s\n' "$(grep -c -a 'AppleH1CLCD' "$f")"
  fi
done
echo "===== DONE ====="
