#!/bin/bash
# Make reconstructed iOS26 SDK's availability macros fully noop for xnu-clang.
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
OSAV="$SDK/usr/include/os/availability.h"
AVAIL="$SDK/usr/include/Availability.h"

# backup once
[ -f "$OSAV.s213bak" ] || cp -a "$OSAV" "$OSAV.s213bak"
[ -f "$AVAIL.s213bak" ] || cp -a "$AVAIL" "$AVAIL.s213bak"
echo "backups: $(ls -la "$OSAV.s213bak" "$AVAIL.s213bak" 2>/dev/null | wc -l)"

python3 - "$OSAV" "$AVAIL" <<'PY'
import sys, re
for path in sys.argv[1:]:
    s = open(path).read()
    # Strategy: after the include guard's #define, inject a block that forces every
    # availability macro to noop. But the file itself re-#defines them under #if branches,
    # which would override ours. Instead, rewrite the *real* definitions to noop in place.
    #
    # The real (non-noop) definitions all expand to __API_XXX_GET_MACRO(...) or
    # __AVAILABILITY_INTERNAL##. Neutralize any #define line whose RHS contains
    # GET_MACRO or __AVAILABILITY_INTERNAL, by turning it into an empty variadic macro.
    lines = s.splitlines(keepends=True)
    out = []
    changed = 0
    for ln in lines:
        m = re.match(r'^(\s*#\s*define\s+)([A-Za-z0-9_]+)(\([^)]*\))?(.*)$', ln.rstrip('\n'))
        if m:
            name = m.group(2)
            rhs = m.group(4)
            if ('GET_MACRO' in rhs or '__AVAILABILITY_INTERNAL' in rhs) and (
                name.startswith('API_') or name.startswith('__API_') or
                name.startswith('__OSX_AVAILABLE') or name.startswith('__IPHONE_AVAILABLE') or
                name.startswith('NS_AVAILABLE') or name.startswith('NS_DEPRECATED')):
                out.append(m.group(1) + name + '(...)' + '\n')
                changed += 1
                continue
        out.append(ln)
    open(path, 'w').write(''.join(out))
    print(f"{path}: neutralized {changed} macro definitions")
PY
echo "=== verify no real GET_MACRO expansions remain in active defs ==="
grep -nE '^ *# *define +(__?API_|__OSX_AVAILABLE).*GET_MACRO' "$OSAV" "$AVAIL" | head
echo DONE
