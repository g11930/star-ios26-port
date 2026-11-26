#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()

start = s.index('/* The loader keeps a ring buffer')
end = s.index('for (int i = 0; i < n; i++) {\n\t\tloader_log_putc(line[i]);\n\t}\n}\n') + len('for (int i = 0; i < n; i++) {\n\t\tloader_log_putc(line[i]);\n\t}\n}\n')
block = s[start:end]
s = s[:start] + s[end:]

anchor = '#include <sys/systm.h>\n'
s = s.replace(anchor, anchor + '#include <stdarg.h>\n\n' + block + '\n', 1)
open(p, 'w').write(s)
print('moved helper to top; first call line now after decl:', s.index('goodix_trace("goodix: no command database') > s.index('goodix_trace(const char *format, ...)\n{'))
