#!/bin/bash
set -u
cd /root/dsc26_zeta_scripts || exit 1
BASE="https://raw.githubusercontent.com/none24smu/UniXNU-zeta/825d75028a3aefc2035164591ba9074837e39979/scripts"
for f in zeta_userland_pauth.py zeta_pauth_plan.py zeta_userland_code.py zeta_dyld_cache.py prove-zeta-dyld-cache.py rewrite-zeta-dyld-cache.py rewrite-zeta-userland.py make-zeta-trust-bundle.py; do
  echo -n "$f: "
  curl -sSL --max-time 40 "$BASE/$f" -o "$f" && wc -c < "$f" || echo FAIL
done
