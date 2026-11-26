import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOService.cpp"
shutil.copyfile(P, P + ".s102-pre.bak")
src = open(P).read()

old = '''// public version
OSIterator *
IOService::getMatchingServices( OSDictionary * matching )
{
	OSIterator *        iter;
'''
new = '''// public version
OSIterator *
IOService::getMatchingServices( OSDictionary * matching )
{
	OSIterator *        iter;

	/* s102: every registry query, whichever path it came in on (diagnostics only) */
	{
		static unsigned sQueryCount;

		if (matching != NULL && sQueryCount < 80) {
			OSObject * cls = matching->getObject("IOProviderClass");
			OSSymbol * sym = OSDynamicCast(OSSymbol, cls);
			OSString * str = OSDynamicCast(OSString, cls);

			if (sym != NULL || str != NULL) {
				char who[32] = "?";

				sQueryCount++;
				proc_selfname(who, sizeof(who));
				IOLog("IOSvcQuery2: %s[%d] asks for %s\\n", who, proc_selfpid(),
				    sym != NULL ? sym->getCStringNoCopy() : str->getCStringNoCopy());
			}
		}
	}
'''
if old not in src:
    print("ANCHOR FAIL"); sys.exit(1)
src = src.replace(old, new, 1)

if "IOKit/IOLib.h" not in src and '#include "IOKit/IOLib.h"' not in src:
    pass

open(P, "w").write(src)
print("PATCHED")
