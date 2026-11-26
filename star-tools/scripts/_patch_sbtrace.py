p = "/root/star26/hackios-xnu-userland/userland/src/inject/sbtrace.c"
s = open(p).read()

old = """static CFMutableDictionaryRef
trace_IOServiceMatching(const char *name)
{
	CFMutableDictionaryRef result;

	g_calls[0]++;
	if (g_depth[0] > 1) {                   /* our own call coming back: never recurse */
		return real_IOServiceMatching != NULL ? real_IOServiceMatching(name) : NULL;
	}
	if (spend(2, 120)) {
		say("trace: %s IOServiceMatching(\\"%s\\")", g_prog, name != NULL ? name : "(null)");
	}
	g_depth[0]++;
	result = real_IOServiceMatching != NULL ? real_IOServiceMatching(name) : NULL;
	g_depth[0]--;
	return result;
}"""

new = """/*
 * The dictionary IOServiceMatching makes, made here.  Needed because dyld interposing can
 * leave this library with no way back to the original: dlsym on IOKit returns this file's
 * own replacement (the log says "originals 1111 ... self=1111"), the pointers are then set
 * to NULL, and the interposing stays in force.  Returning NULL there is what made every
 * match in SpringBoard and backboardd look like "the service is not there": the call never
 * leaves the process.  A provider-class dictionary is all IOServiceMatching ever built.
 */
static CFMutableDictionaryRef
sbtrace_matching_dictionary(const char *name)
{
	CFMutableDictionaryRef dict;
	CFStringRef cls;

	if (name == NULL) {
		return NULL;
	}
	dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks,
	    &kCFTypeDictionaryValueCallBacks);
	if (dict == NULL) {
		return NULL;
	}
	cls = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingUTF8);
	if (cls == NULL) {
		CFRelease(dict);
		return NULL;
	}
	CFDictionarySetValue(dict, CFSTR("IOProviderClass"), cls);
	CFRelease(cls);
	return dict;
}

static CFMutableDictionaryRef
trace_IOServiceMatching(const char *name)
{
	CFMutableDictionaryRef result;

	g_calls[0]++;
	if (g_depth[0] > 1) {                   /* our own call coming back: never recurse */
		return real_IOServiceMatching != NULL ? real_IOServiceMatching(name) :
		    sbtrace_matching_dictionary(name);
	}
	if (spend(2, 120)) {
		say("trace: %s IOServiceMatching(\\"%s\\")", g_prog, name != NULL ? name : "(null)");
	}
	g_depth[0]++;
	result = real_IOServiceMatching != NULL ? real_IOServiceMatching(name) :
	    sbtrace_matching_dictionary(name);
	g_depth[0]--;
	if (result != NULL && real_IOServiceMatching == NULL && spend(2, 40)) {
		say("trace: %s IOServiceMatching(\\"%s\\") = a dictionary made here",
		    g_prog, name != NULL ? name : "(null)");
	}
	return result;
}"""

assert old in s, "pattern not found"
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("sbtrace patched")
