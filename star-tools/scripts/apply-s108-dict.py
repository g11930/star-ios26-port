import shutil, sys

P = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
BAK = P + ".s108-pre.bak"
shutil.copyfile(BAK, P)
lines = open(P).read().split("\n")

helper = '''/* s108: dump the whole matching dictionary (keys AND values) so IONameMatch-style
 * lookups -- IOServiceNameMatching("disp0") and friends -- stop being invisible.
 */
static void
starLogMatchDict(const char * tag, OSDictionary * dict)
{
	static unsigned sDumpCount;
	OSCollectionIterator * it;
	OSObject * key;
	char buf[320];
	unsigned n = 0;

	if (dict == NULL || sDumpCount >= 80) {
		return;
	}
	it = OSCollectionIterator::withCollection(dict);
	if (it == NULL) {
		return;
	}
	sDumpCount++;
	buf[0] = '\\0';
	while ((key = it->getNextObject()) != NULL && n < 8) {
		const OSSymbol * ks = OSDynamicCast(OSSymbol, key);
		OSObject * v;
		OSSymbol * vs;
		OSString * str;
		const char * txt;

		if (ks == NULL) {
			continue;
		}
		v = dict->getObject(key);
		vs = OSDynamicCast(OSSymbol, v);
		str = OSDynamicCast(OSString, v);
		if (vs != NULL) {
			txt = vs->getCStringNoCopy();
		} else if (str != NULL) {
			txt = str->getCStringNoCopy();
		} else {
			txt = "?";
		}
		if (n != 0) {
			snprintf(buf + strlen(buf), sizeof(buf) - strlen(buf), " ");
		}
		snprintf(buf + strlen(buf), sizeof(buf) - strlen(buf), "%s=%s",
		    ks->getCStringNoCopy(), txt);
		n++;
	}
	it->release();
	IOLog("IOSvcDict: %s %s\\n", tag, buf);
}
'''

# 1) insert the helper before the first matching routine
for i, l in enumerate(lines):
    if l.startswith("static kern_return_t") and "internal_io_service_get_matching_services(" in lines[i + 1]:
        lines[i:i] = helper.split("\n")
        break
else:
    print("HELPER ANCHOR FAIL"); sys.exit(1)

def cut_block(marker, tag):
    idx = next(i for i, l in enumerate(lines) if marker in l)
    open_i = max(i for i in range(idx) if lines[i].strip() == "{")
    depth = 0
    for j in range(open_i, len(lines)):
        depth += lines[j].count("{") - lines[j].count("}")
        if depth == 0:
            close_i = j
            break
    lines[open_i:close_i + 1] = ['\t\tstarLogMatchDict("%s", dict);' % tag]

cut_block("static unsigned sMatchCount2;", "matchList")
cut_block("static unsigned sMatchCount;", "match")

txt = "\n".join(lines)
# drop the now-pointless s106 comment above the single-service call
txt = txt.replace("\t\t/* s106: which class a userland process asks to match (diagnostics only) */\n", "")
open(P, "w").write(txt)
print("PATCHED")
