p = "/root/star26/star-native/iokit/Kernel/IOService.cpp"
s = open(p).read()

# remove the function-scope declarations
bad = '\t\textern "C" int proc_selfpid(void);\n\t\textern "C" void proc_selfname(char * buf, int size);\n\n'
if bad not in s:
    print("REMOVE ANCHOR FAIL")
    raise SystemExit(1)
s = s.replace(bad, "", 1)

anchor = "// public version\nOSIterator *\nIOService::getMatchingServices( OSDictionary * matching )"
if anchor not in s:
    print("INSERT ANCHOR FAIL")
    raise SystemExit(1)

decl = '''extern "C" {
	int proc_selfpid(void);
	void proc_selfname(char * buf, int size);
}

'''
s = s.replace(anchor, decl + anchor, 1)
open(p, "w").write(s)
print("FIXED")
