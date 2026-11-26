#!/bash
S111=/mnt/c/ios26/s111-live.bin
S112=/mnt/c/ios26/s112-live.bin
echo "===== 1) 两份日志规模 ====="
wc -c "$S111" "$S112"
echo -n "s111 backboardd 行: "; strings "$S111" | grep -ci backboardd
echo -n "s112 backboardd 行: "; strings "$S112" | grep -ci backboardd
echo -n "s111 SpringBoard 行: "; strings "$S111" | grep -ci SpringBoard
echo -n "s112 SpringBoard 行: "; strings "$S112" | grep -ci SpringBoard
echo
echo "===== 2) s112 里 backboardd 相关原文 ====="
strings -n 8 "$S112" | grep -i backboardd | head -20
echo
echo "===== 3) s112 有无注入失败/镜像错误 ====="
strings -n 8 "$S112" | grep -iE "inject|dylib|dyld: |exec_inject|kdload" | head -20
echo
echo "===== 4) s112 有无 FBSystemShellInitialize / 前台断言 ====="
strings -n 8 "$S112" | grep -iE "FBSystemShell|frontboard|Alloc com.apple" | head -10
echo
echo "===== 5) s112 最后 30 行 ====="
strings -n 6 "$S112" | tail -30
echo "===== DONE ====="
</bash>
