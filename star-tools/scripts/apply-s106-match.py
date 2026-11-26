import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
shutil.copyfile(P, P + ".s106-pre.bak")
src = open(P).read()

# 1) single-service variant
old1 = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		IOTaskRegistryCompatibilityMatching(current_task(), dict);
		*service = IOService::copyMatchingService( dict );'''
new1 = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		/* s106: which class a userland process asks to match (diagnostics only) */
		{
			static unsigned sMatchCount;

			if (sMatchCount < 150) {
				OSObject * cls = dict->getObject("IOProviderClass");
				OSSymbol * sym = OSDynamicCast(OSSymbol, cls);
				OSString * str = OSDynamicCast(OSString, cls);

				if (sym != NULL || str != NULL) {
					sMatchCount++;
					IOLog("IOSvcMatch: asks %s\\n",
					    sym != NULL ? sym->getCStringNoCopy() : str->getCStringNoCopy());
				}
			}
		}
		IOTaskRegistryCompatibilityMatching(current_task(), dict);
		*service = IOService::copyMatchingService( dict );'''
if old1 not in src:
    print("SINGLE ANCHOR FAIL"); sys.exit(1)
src = src.replace(old1, new1, 1)

# 2) plural variant
old2 = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		IOTaskRegistryCompatibilityMatching(current_task(), dict);
		*existing = IOUserIterator::withIterator(IOService::getMatchingServices( dict ));'''
new2 = '''	if ((dict = OSDynamicCast( OSDictionary, obj))) {
		{
			static unsigned sMatchCount2;

			if (sMatchCount2 < 150) {
				OSObject * cls = dict->getObject("IOProviderClass");
				OSSymbol * sym = OSDynamicCast(OSSymbol, cls);
				OSString * str = OSDynamicCast(OSString, cls);

				if (sym != NULL || str != NULL) {
					sMatchCount2++;
					IOLog("IOSvcMatchList: asks %s\\n",
					    sym != NULL ? sym->getCStringNoCopy() : str->getCStringNoCopy());
				}
			}
		}
		IOTaskRegistryCompatibilityMatching(current_task(), dict);
		*existing = IOUserIterator::withIterator(IOService::getMatchingServices( dict ));'''
if old2 not in src:
    print("PLURAL ANCHOR FAIL"); sys.exit(1)
src = src.replace(old2, new2, 1)

open(P, "w").write(src)
print("PATCHED")
