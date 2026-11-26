#!/usr/bin/env python3
"""
Transplant the WORKING iOS16 STM FTS K2 touch driver into the iOS26 kernel tree.
Base: /root/star-build/xnu-src/xnu-8796.121.2/bsd/dev/redwood_goodix.c (2393 lines,
      real-device verified: stm: chip id 0x3639, sense-on, 13/23/33 events)
Target: /root/star26/star-native/bsd/dev/star/annibale_goodix.c (1600 lines, no STM)
Mechanical renames + keep iOS26's loader_log_putc-based trace implementation.
"""
import os, sys

SRC = '/root/star-build/xnu-src/xnu-8796.121.2/bsd/dev/redwood_goodix.c'
DST = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
BAK = DST + '.s192-pre-stm.bak'

src = open(SRC, encoding='utf-8').read()
if not os.path.exists(BAK):
    open(BAK, 'w', encoding='utf-8').write(open(DST, encoding='utf-8').read())
    print('backup ->', BAK)

# --- 1) header: sys/redwood_input.h -> sys/annibale_input.h
src = src.replace('#include <sys/redwood_input.h>', '#include <sys/annibale_input.h>')

# --- 2) touch post API: REDWOOD_TOUCH_* -> ANNIBALE_TOUCH_*, redwood_touch_post -> annibale_touch_post
src = src.replace('redwood_touch_post', 'annibale_touch_post')
src = src.replace('REDWOOD_TOUCH_', 'ANNIBALE_TOUCH_')

# --- 3) init function: redwood_goodix_init -> annibale_goodix_init
src = src.replace('redwood_goodix_init', 'annibale_goodix_init')

# --- 4) latency API: redwood_tl -> annibale_tl
src = src.replace('redwood_tl', 'annibale_tl')

# --- 5) logging: gdlog -> goodix_trace (the whole file uses gdlog)
src = src.replace('gdlog', 'goodix_trace')

# --- 6) Replace the whole (renamed) gdlog function with iOS26's loader_log_putc version ---
# After step 5 the function is named goodix_trace but its body calls loader_log_line and
# has no va_end-safe putc loop. Replace the entire definition atomically.
old_fn = '''static void
goodix_trace(const char *format, ...) __printflike(1, 2);

static void
goodix_trace(const char *format, ...)
{
\tchar line[512];
\tva_list list;

\tva_start(list, format);
\tvsnprintf(line, sizeof(line), format, list);
\tva_end(list);
\tloader_log_line(line);
}'''
new_fn = '''extern void loader_log_putc(char c);

static void
goodix_trace(const char *format, ...) __printflike(1, 2);

static void
goodix_trace(const char *format, ...)
{
\tchar line[512];
\tva_list list;
\tint n;

\tva_start(list, format);
\tn = vsnprintf(line, sizeof(line), format, list);
\tva_end(list);
\tif (n < 0) return;
\tif (n > (int)sizeof(line) - 1) n = (int)sizeof(line) - 1;
\tfor (int i = 0; i < n; i++) loader_log_putc(line[i]);
}'''
if old_fn in src:
    src = src.replace(old_fn, new_fn, 1)
    print('replaced whole trace function')
else:
    print('ERROR: trace function not matched -- ABORT')
    sys.exit(2)

# --- 7) check remaining redwood references that shouldn't be renamed blindly ---
left = [l for l in src.split('\n') if 'redwood' in l.lower() and 'redwood_goodix' not in l.lower()]
print('remaining redwood refs:', len(left))
for l in left[:12]:
    print('   ', l.strip()[:150])

open(DST, 'w', encoding='utf-8').write(src)
print('WROTE', DST, len(src), 'bytes', src.count('\n')+1, 'lines')
