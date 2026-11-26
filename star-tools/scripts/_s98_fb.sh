#!/bash
L=/mnt/c/ios26/s98-live.bin
echo "===== A) 帧缓冲统计（s98-frame.raw） ====="
python3 - <<'PY'
import numpy as np
a=np.fromfile("/mnt/c/ios26/s98-frame.raw",dtype=np.uint8)
print("len",a.size,"nonzero",int((a!=0).sum()),"max",int(a.max()))
b=a.reshape(-1,4)
print("BGR mean",b[:,:3].mean(axis=0).round(2),"alpha mean",round(float(b[:,3].mean()),2))
print("unique colors (sample):",len(np.unique(b[::1000,:3],axis=0)))
PY
echo
echo "===== B) 背光/显示相关内核日志 ====="
strings -n 8 "$L" | grep -iE "backlight|nits|MiniIOMobileFramebuffer|panel|display" | head -15
echo
echo "===== C) WindowServer/场景计数 ====="
strings "$L" | grep -ci "windowserver"; strings "$L" | grep -ci "SBScene\|scene ID"
echo
echo "===== DONE ====="
