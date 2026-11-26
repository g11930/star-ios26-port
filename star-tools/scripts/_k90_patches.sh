#!/bash
cd /root/k90-src || exit 1
echo "===== xnu26/patches 列表（找 iokit/userclient/registry 相关）====="
git ls-files | grep -E "^xnu26/patches/" | sed 's#xnu26/patches/##' | head -40
echo
echo "===== tools/tests 名称 ====="
git ls-files | grep -E "^tools/tests/" | sed 's#tools/tests/##' | head -40
echo
echo "===== docs ====="
git ls-files | grep -E "^docs/" | head
