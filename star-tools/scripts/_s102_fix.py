p = "/root/star26/star-native/iokit/Kernel/IOService.cpp"
s = open(p).read()

old = '''\t\tif (matching != NULL && sQueryCount < 80) {\n'''
new = '''\t\textern int proc_selfpid(void);\n\t\textern void proc_selfname(char * buf, int size);\n\n\t\tif (matching != NULL && sQueryCount < 80) {\n'''

if old not in s:
    print("ANCHOR FAIL")
    raise SystemExit(1)
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("FIXED")
