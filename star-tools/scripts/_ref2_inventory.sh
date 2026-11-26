#!/bin/bash
# inventory the cloned reference repos
for d in /root/ref2/warsaw-xnu-kernel-RedmiK90Ultra /root/ref2/hackios-redmi-k90-annibale /root/ref2/hakios-arm64e-dada; do
    echo "===== $d ====="
    if [ ! -d "$d" ]; then
        echo "(not cloned yet)"
        continue
    fi
    ls "$d" | head -25
    echo "---- README (head 40) ----"
    head -40 "$d/README.md" 2>/dev/null || head -40 "$d/readme.md" 2>/dev/null || echo "(no README)"
    echo
done
