import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
shutil.copyfile(P, P + ".s109-pre.bak")
src = open(P).read()

old = '''		IOTaskRegistryCompatibilityMatching(current_task(), dict);

		if ((sym == gIOPublishNotification)'''
new = '''		IOTaskRegistryCompatibilityMatching(current_task(), dict);

		/* s109: who subscribes to which service notification, and on what dict */
		IOLog("IOSvcNotify: type=%s\\n", notification_type);
		starLogMatchDict("notify", dict);

		if ((sym == gIOPublishNotification)'''
if old not in src:
    print("ANCHOR FAIL"); sys.exit(1)
src = src.replace(old, new, 1)

# raise the dump cap so notifications are not starved by the 80 earlier dicts
src = src.replace("\tif (dict == NULL || sDumpCount >= 80) {",
                  "\tif (dict == NULL || sDumpCount >= 220) {", 1)

open(P, "w").write(src)
print("PATCHED")
