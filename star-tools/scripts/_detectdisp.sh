#!/bash
L=/mnt/c/ios26/s109-live.bin
echo "===== 日志里的 detectDisplays / annibale 钩子痕迹 ====="
strings -n 8 "$L" | grep -iE "detectDisplays|new_server|not what was expected" | head -10
echo
echo "===== annibale: 前缀行（前 30）====="
strings -n 8 "$L" | grep -F "annibale:" | head -30
echo
echo "===== s105 里同样内容 ====="
strings -n 8 /mnt/c/ios26/s105-live.bin | grep -iE "detectDisplays|annibale:" | head -20
echo "===== DONE ====="
</bash>
