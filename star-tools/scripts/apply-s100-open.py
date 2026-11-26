import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp"
shutil.copyfile(P, P + ".s100-pre.bak")
src = open(P).read()

# 1) declaration inside class body
decl_anchor = "\tvirtual bool start(IOService * provider) APPLE_KEXT_OVERRIDE;\n"
if decl_anchor not in src:
    print("DECL ANCHOR FAIL"); sys.exit(1)
decl_new = decl_anchor + \
"\t/* s100: diagnostics only -- log who opens disp0, then let IOService do exactly what it did */\n" + \
"\tvirtual IOReturn newUserClient(task_t owningTask, void * securityID, UInt32 type,\n" + \
"\t    OSDictionary * properties, IOUserClient ** handler) APPLE_KEXT_OVERRIDE;\n"
src = src.replace(decl_anchor, decl_new, 1)

# 2) implementation before the user client include
inc_anchor = '#include "MiniFramebufferUserClient.inc"'
if inc_anchor not in src:
    print("INC ANCHOR FAIL"); sys.exit(1)
impl = '''IOReturn
IOMobileFramebuffer::newUserClient(task_t owningTask, void * securityID, UInt32 type,
    OSDictionary * properties, IOUserClient ** handler)
{
	char who[32] = "?";

	proc_selfname(who, sizeof(who));
	IOLog("MiniIOMobileFramebuffer: s100 open asked by %s[%d] type %u props=%p\\n",
	    who, proc_selfpid(), (unsigned) type, properties);

	IOReturn result = IOService::newUserClient(owningTask, securityID, type, properties, handler);

	IOLog("MiniIOMobileFramebuffer: s100 open -> 0x%x client=%p\\n", result,
	    (handler != NULL) ? (void *) *handler : NULL);
	return result;
}

'''
src = src.replace(inc_anchor, impl + inc_anchor, 1)

# 3) startup confirmation line
start_anchor = "\tregisterService();\n\treturn true;\n}"
if start_anchor not in src:
    print("START ANCHOR FAIL"); sys.exit(1)
src = src.replace(start_anchor,
"\tregisterService();\n"
"\tIOLog(\"MiniIOMobileFramebuffer: s100 started, class key %s, %ux%u\\n\",\n"
"\t    \"IOMobileFramebufferUserClient\", fWidth, fHeight);\n"
"\treturn true;\n}", 1)

open(P, "w").write(src)
print("PATCHED")
