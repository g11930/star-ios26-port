import re

p = "/root/star26/star-native/iokit/Kernel/AnnibaleGPU.cpp"
s = open(p).read()

old = """	case kMsmGetParam:
		IOLockLock(gGPULock);
		ret = annibale_gpu_parameter(r.param.param, &r.param.value) ? kIOReturnSuccess : kIOReturnBadArgument;
		IOLockUnlock(gGPULock);
		break;"""

new = """	case kMsmGetParam:
		IOLockLock(gGPULock);
		ret = annibale_gpu_parameter(r.param.param, &r.param.value) ? kIOReturnSuccess : kIOReturnBadArgument;
		IOLockUnlock(gGPULock);
		{
			/* who asks for what, and what it is told: freedreno builds its screen out of these */
			static unsigned said;
			char who[32] = "?";

			if (said++ < 40) {
				proc_selfname(who, sizeof(who));
				IOLog("AnnibaleGPU: GET_PARAM %#x -> %s %#llx (%s)\\n", r.param.param,
				    ret == kIOReturnSuccess ? "ok" : "REFUSED",
				    (unsigned long long)r.param.value, who);
			}
		}
		break;"""

assert old in s
s = s.replace(old, new, 1)
open(p, "w").write(s)
print("param logging added")