import re

p = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
s = open(p).read()

ENTRY = ('\t{\n\t\tchar who[32] = "?";\n\t\tstatic unsigned inCount;\n\n'
         '\t\tif (inCount++ < 24) {\n\t\t\tproc_selfname(who, sizeof(who));\n'
         '\t\t\tIOLog("IOSvcIn: %s[%d] %s port %#x\\n", who, proc_selfpid(), __func__, main_port);\n'
         '\t\t}\n\t}\n')

funcs = [
    "is_io_service_get_matching_service_ool",
    "is_io_service_get_matching_service_bin",
    "is_io_service_get_matching_services_ool",
    "is_io_service_get_matching_services_bin",
]

count = 0
for f in funcs:
    # find "kern_return_t\n<name>(\n" then the first "{\n" after it
    m = re.search(r"kern_return_t\n" + f + r"\(\n", s)
    if not m:
        print("missing", f)
        continue
    brace = s.find("\n{\n", m.end())
    if brace < 0:
        print("no brace", f)
        continue
    s = s[:brace + 3] + ENTRY + s[brace + 3:]
    count += 1

open(p, "w").write(s)
print("instrumented", count)
