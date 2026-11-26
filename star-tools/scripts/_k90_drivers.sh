#!/bash
cd /root/k90-src || exit 1
echo "===== K90 iokit/Kernel 全部 Mini* / Annibale* ====="
git ls-files | grep -E "xnu/files/iokit/Kernel/" | sed 's#.*/##' | sort
echo
echo "===== K90 bsd/dev 驱动 ====="
git ls-files | grep -E "xnu/files/bsd/dev/" | sed 's#.*/##' | sort | head -40
echo
echo "===== K90 是否提到 backboardd / display 的文档或脚本 ====="
git ls-files | grep -iE "docs/|notes|progress|status" | head -10
