#!/usr/bin/env python3
import re
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()

helper = '''
/* The loader keeps a ring buffer it hands to `fastboot oem log`, and the kernel's own
 * printf path stops reaching it once userland owns the console. Write there directly. */
extern void loader_log_putc(char c);

static void
goodix_log(const char *format, ...) __printflike(1, 2);

static void
goodix_log(const char *format, ...)
{
	char line[256];
	va_list list;
	int n;

	va_start(list, format);
	n = vsnprintf(line, sizeof(line), format, list);
	va_end(list);
	if (n < 0) {
		return;
	}
	if (n > (int)sizeof(line) - 1) {
		n = (int)sizeof(line) - 1;
	}
	for (int i = 0; i < n; i++) {
		loader_log_putc(line[i]);
	}
}
'''

if 'loader_log_putc' not in s:
    anchor = '#include "annibale_focaltech_fw.h"'
    s = s.replace(anchor, anchor + '\n#include <stdarg.h>\n' + helper, 1)

# every diagnostic in this driver goes to the loader's log
s = re.sub(r'\bprintf\(', 'goodix_log(', s)
s = s.replace('goodix_log("goodix:', 'goodix_log("goodix:')
open(p, 'w').write(s)
print('helper added:', 'goodix_log(const char' in s, 'printf left:', s.count('printf('))
