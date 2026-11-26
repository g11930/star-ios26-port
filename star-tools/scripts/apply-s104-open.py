import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
shutil.copyfile(P, P + ".s104-pre.bak")
src = open(P).read()

old = '''		res = service->newUserClient( owningTask, (void *) owningTask,
		    connect_type, propertiesDict, &client );
'''
new = '''		/* s104: every IOServiceOpen, whoever makes it (diagnostics only) */
		{
			static unsigned sOpenCount;

			if (sOpenCount < 300) {
				char who[32] = "?";

				sOpenCount++;
				proc_selfname(who, sizeof(who));
				IOLog("IOSvcOpen: %s[%d] opens %s(%s)\\n", who, proc_selfpid(),
				    service->getName() != NULL ? service->getName() : "?",
				    service->getMetaClass() != NULL ? service->getMetaClass()->getClassName() : "?");
			}
		}
		res = service->newUserClient( owningTask, (void *) owningTask,
		    connect_type, propertiesDict, &client );

		if (client != NULL) {
			char who2[32] = "?";

			proc_selfname(who2, sizeof(who2));
			IOLog("IOSvcOpen: %s[%d] -> 0x%x\\n", who2, proc_selfpid(), res);
		}
'''
if old not in src:
    print("ANCHOR FAIL"); sys.exit(1)
src = src.replace(old, new, 1)
open(P, "w").write(src)
print("PATCHED")
