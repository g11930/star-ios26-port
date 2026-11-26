p = "/root/star26/star-native/iokit/Kernel/IOService.cpp"
s = open(p).read()

old = '\t\textern int proc_selfpid(void);\n\t\textern void proc_selfname(char * buf, int size);\n'
new = '\t\textern "C" int proc_selfpid(void);\n\t\textern "C" void proc_selfname(char * buf, int size);\n'

if old not in s:
    print("ANCHOR FAIL")
    raise SystemExit(1)
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("FIXED")
