#!/bash
echo "===== s105（属性在、device=1）的 sbmetal 全序列 ====="
strings -n 6 /mnt/c/ios26/s105-live.bin | grep -F "sbmetal26" | head -50
echo
echo "===== s105 里 say 行里跟渲染相关的 ====="
strings -n 8 /mnt/c/ios26/s105-live.bin | grep -E "^say [0-9]+ sbmetal" | head -20
echo "===== DONE ====="
</bash>
