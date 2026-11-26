#!/bash
L=/mnt/c/ios26/s113-live.bin
echo -n "annibale: metal 行数: "; strings "$L" | grep -c "annibale: metal"
strings -n 6 "$L" | grep "annibale: metal" | head -6
echo -n "annibale: 前缀总行数: "; strings "$L" | grep -c "annibale:"
echo "--- 全部 annibale: 行（去重）:"
strings -n 6 "$L" | grep "annibale:" | sed 's/[0-9a-fx]\{4,\}/N/g' | sort | uniq -c | sort -rn | head -12
echo "===== DONE ====="
</bash>
