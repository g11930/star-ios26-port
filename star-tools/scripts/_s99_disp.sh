#!/bash
L=/mnt/c/ios26/s99-live.bin
echo "===== A) disp0 / 用户客户端 / swap ====="
strings -n 8 "$L" | grep -iE "disp0|userclient|user client|open by|swap|vsync|setDisplayMode|framebuffer" | head -25
echo
echo "===== B) backboardd 显示相关错误 ====="
strings -n 8 "$L" | grep -iE "backboardd.*(display|Display)" | grep -iE "fail|error|no |unsupport|missing|wait" | head -15
echo
echo "===== C) SpringBoard 场景/窗口 ====="
strings -n 8 "$L" | grep -E "SpringBoard\[[0-9]+" | grep -iE "scene|window|display|render|first" | head -20
echo
echo "===== DONE ====="
