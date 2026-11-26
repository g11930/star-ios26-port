#!/bash
L=/mnt/c/ios26/s108-live.bin
echo "===== FBSystemShell / assertion 相关 ====="
strings -n 20 "$L" | grep -iE "FBSystemShell|systemShell|FBSSystemService" | head -12
echo
echo "===== runningboardd 行（最后 20）====="
strings -n 20 "$L" | grep "runningboardd" | tail -20
echo
echo "===== SpringBoard 里 assertion / 完成 关键字 ====="
strings -n 20 "$L" | grep -E "SpringBoard\[[0-9]+:" | grep -iE "assert|Acquir|Invalidat|display|scene|window" | tail -15
echo "===== DONE ====="