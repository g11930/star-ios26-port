import re
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()
if 'goodix: thread up' in s:
    print('already'); raise SystemExit
m = re.search(r'goodix_thread\(__unused void \*parameter, __unused wait_result_t result\)\n\{\n', s)
s = s[:m.end()] + '\tprintf("goodix: thread up, probing in 20 s\\n");\n' + s[m.end():]
open(p, 'w').write(s)
print('marker added')
