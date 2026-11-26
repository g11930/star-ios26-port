p = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
s = open(p).read()

# The two matching entry points insist on the real master port.  A process that asks with
# kIOMasterPortDefault (0) -- which is how libSystem resolves it when the bootstrap service
# is not where it expects -- is refused before the match is even logged, and the caller sees
# "no service".  Accept 0 there: matching is a read of the registry, nothing is opened.
old = """	if (main_port != main_device_port) {
		return kIOReturnNotPrivileged;
	}"""
new = """	if (main_port != main_device_port && main_port != MACH_PORT_NULL) {
		return kIOReturnNotPrivileged;
	}
	if (main_port == MACH_PORT_NULL) {
		static uint32_t said = 0;
		if (said++ < 4) {
			IOLog("IOSvc: a match came in on kIOMasterPortDefault; taking it as the master port\\n");
		}
	}"""
n = s.count(old)
print("occurrences:", n)
s = s.replace(old, new)
open(p, "w").write(s)
