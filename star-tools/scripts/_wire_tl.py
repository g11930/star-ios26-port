#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_input.c'
s = open(p).read()

# a "tl:" logger the ported touch driver calls; the reference wrote these to the loader's log,
# here they go to the kernel's own log
if 'void\nannibale_tl' not in s:
    s = s.replace('#include <sys/uiomove.h>', '#include <sys/uiomove.h>')
    s = s.replace('#include <sys/uio.h>\n', '#include <sys/uio.h>\n#include <sys/kernel.h>\n#include <stdarg.h>\n', 1)
    s = s.replace('extern void annibale_adreno_init(void);\n',
                  'extern void annibale_adreno_init(void);\nextern void annibale_goodix_init(void);\n\n'
                  '/* The touch driver\'s timing lines ("tl: ..."), on the kernel log. */\n'
                  'void annibale_tl(const char *format, ...) __printflike(1, 2);\n\n'
                  'void\nannibale_tl(const char *format, ...)\n{\n'
                  '\tchar line[192];\n\tva_list list;\n\n'
                  '\tva_start(list, format);\n'
                  '\tvsnprintf(line, sizeof(line), format, list);\n'
                  '\tva_end(list);\n'
                  '\tprintf("%s", line);\n}\n', 1)

# the driver is woken from here, as the reference\'s input init woke it
if 'annibale_goodix_init();' not in s:
    s = s.replace('\tannibale_adreno_init();\n}',
                  '\tannibale_goodix_init();          /* boot-arg touchscreen=1: the FTS touch screen */\n'
                  '\tannibale_adreno_init();\n}', 1)

open(p, 'w').write(s)
print('input file now calls goodix_init:', 'annibale_goodix_init();' in s)
print('tl logger present:', 'annibale_tl(const char *format' in s)
