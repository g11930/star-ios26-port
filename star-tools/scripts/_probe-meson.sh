#!/bin/bash
set -u
B=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
echo "== build dir =="
ls -la $B | head -25
echo
echo "== timestamps =="
ls -l --time-style=long-iso $B/src/gallium/drivers/freedreno/libannibaleair.dylib
ls -l --time-style=long-iso $M/src/compiler/air/air_metal_lowering.inc
ls -l --time-style=long-iso /root/star26/s41/work/root/lib/libannibaleair.dylib
echo
echo "== ninja status (dry) =="
command -v ninja && ninja -C $B -n 2>&1 | head -15
echo
echo "== meson options =="
ls $B/meson-info 2>/dev/null | head
python3 - <<'PY'
import json
p="/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/meson-info/intro-buildoptions.json"
try:
    d=json.load(open(p))
    for o in d:
        if o.get('section') in ('gallium','compiler','buildtype','platforms') or o['name'] in ('gallium-drivers','platforms','buildtype'):
            print(o['section'], o['name'], '=', o['value'])
except Exception as e:
    print("ERR", e)
PY
echo
echo "== mesa build scripts =="
ls -1 /root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/ | head -20
