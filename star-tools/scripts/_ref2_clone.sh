#!/bin/bash
# clone the three reference repos (shallow) into /root/ref2 without touching /root/ref
mkdir -p /root/ref2 || exit 1
cd /root/ref2 || exit 1
for r in \
    https://github.com/jabarin123/warsaw-xnu-kernel-RedmiK90Ultra \
    https://github.com/iola1999/hackios-redmi-k90-annibale \
    https://github.com/superboyyy/hakios-arm64e-dada ; do
    d=$(basename "$r" .git)
    echo "=== clone $d ==="
    if [ -d "$d" ]; then
        echo "exists, skip"
        continue
    fi
    timeout 240 git clone --depth 1 "$r" "$d" 2>&1 | tail -3
done
echo "=== result ==="
ls -la /root/ref2/
