#!/bash
echo "===== 找 inject.conf ====="
find /root -maxdepth 6 -name "inject.conf" 2>/dev/null | head -10
echo
echo "===== 最新那份内容 ====="
f=$(ls -t /root/star26/hackios-xnu-userland/userland/*inject* 2>/dev/null | head -1)
echo "candidate: $f"
for c in /root/star26/hackios-xnu-userland/userland/root/annibale/etc/inject.conf \
         /root/star26/hackios-xnu-userland/userland/annibale/etc/inject.conf \
         /root/star-build/root/annibale/etc/inject.conf; do
  [ -f "$c" ] && { echo "== $c"; cat "$c"; }
done
echo
echo "===== 用户态源码里谁打开 IOMobileFramebuffer / disp0 ====="
grep -rln "IOMobileFramebufferOpen\|IOServiceMatching(\"disp0\"\|IONameMatch.*disp0\|\"disp0\"" /root/star26/hackios-xnu-userland/userland/src 2>/dev/null | head -10
echo "===== DONE ====="
</bash>
