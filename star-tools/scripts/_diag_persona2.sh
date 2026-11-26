#!/bin/bash
set +e
F=/tmp/logdump_cur.bin
echo "=== 2. spawn/xpcproxy ==="
strings -a "$F" | grep -iE "xpcproxy|spawn|could not launch|bootstrap|look.?up|service" | grep -viE "persona" | head -60
echo "=== 3. cfprefsd/lsd etc ==="
strings -a "$F" | grep -iE "cfprefsd|configd|securityd|usermanagerd|containermanagerd|MTLCompiler" | head -30
echo "=== 4. launchd state transitions for on-demand ==="
strings -a "$F" | grep -iE "launchd.*(service|spawn|state)|successfully spawned|exited due to" | head -50
