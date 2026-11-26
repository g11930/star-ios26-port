import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
shutil.copyfile(P, P + ".s101-pre.bak")
src = open(P).read()

anchor = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		IOTaskRegistryCompatibilityMatching(current_task(), dict);'''
if anchor not in src:
    print("ANCHOR FAIL"); sys.exit(1)

new = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		/* s101: who asks the registry for which class (diagnostics only) */
		{
			static unsigned sQueryCount;

			if (sQueryCount < 80) {
				OSObject * cls = dict->getObject("IOProviderClass");
				OSSymbol * sym = OSDynamicCast(OSSymbol, cls);
				OSString * str = OSDynamicCast(OSString, cls);

				if (sym != NULL || str != NULL) {
					char who[32] = "?";

					sQueryCount++;
					proc_selfname(who, sizeof(who));
					IOLog("IOSvcQuery: %s[%d] asks for %s\\n", who, proc_selfpid(),
					    sym != NULL ? sym->getCStringNoCopy() : str->getCStringNoCopy());
				}
			}
		}
		IOTaskRegistryCompatibilityMatching(current_task(), dict);'''

src = src.replace(anchor, new, 1)
open(P, "w").write(src)
print("PATCHED")
