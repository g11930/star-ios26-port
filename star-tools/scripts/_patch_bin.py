import re

p = "/root/star26/star-native/iokit/Kernel/IOUserClient.cpp"
s = open(p).read()

old = "\tobj = OSUnserializeXML(matching, matching_size);\n"
new = ("\tobj = OSUnserializeXML(matching, matching_size);\n"
       "\tif (obj == NULL) {\n"
       "\t\t/* iOS 26 sends these dictionaries in the binary form (the _bin trap).  Reading only\n"
       "\t\t * the XML form made every daemon's lookup look like \"no such service\". */\n"
       "\t\tOSSharedPtr<OSString> why;\n"
       "\t\tstatic unsigned binCount;\n"
       "\n"
       "\t\tobj = OSUnserializeBinary(matching, matching_size, why);\n"
       "\t\tif (binCount++ < 8) {\n"
       "\t\t\tIOLog(\"IOSvcIn: a binary dictionary: %s\\n\",\n"
       "\t\t\t    obj != NULL ? \"read\" : (why != NULL ? why->getCStringNoCopy() : \"not read\"));\n"
       "\t\t}\n"
       "\t}\n")

n = s.count(old)
s = s.replace(old, new)
print("patched XML sites:", n)

# make sure the binary unserializer is declared
if '#include "libkern/c++/OSUnserialize.h"' not in s and "OSUnserialize.h" not in s:
    anchor = "#include <libkern/c++/OSSerialize.h>"
    if anchor in s:
        s = s.replace(anchor, anchor + "\n#include <libkern/c++/OSUnserialize.h>", 1)
        print("include added")
    else:
        print("WARN: include anchor not found")

open(p, "w").write(s)