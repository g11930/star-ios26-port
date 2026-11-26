import shutil

p = "/root/star26/star-native/osfmk/ipc/mach_port.c"
shutil.copy(p, p + ".s61d.bak")

s = open(p).read()
old = """\t/* Port is locked and active */
\tservice_port_sblabel = label.iol_service->ispl_sblabel;
\tif (service_port_sblabel) {
\t\t/* Service ports with sandbox labels require filter callbacks. */
\t\tif (!mach_msg_filter_at_least(MACH_MSG_FILTER_CALLBACKS_VERSION_1)) {
\t\t\tip_mq_unlock_label_put(service_port, &label);
\t\t\treturn KERN_NOT_SUPPORTED;
\t\t}
\t\tmach_msg_filter_retain_sblabel_callback(service_port_sblabel);
\t}
\tip_mq_unlock_label_put(service_port, &label);
"""
new = """\t/*
\t * s62 (from dada.patch, same XNU 12377.121.6): the message-filter
\t * callbacks belong to the Sandbox kext, which is absent in this port.
\t * Without them no service port carries an sblabel -- that is exactly the
\t * "nothing to check" case below; report KERN_SUCCESS with policy id 0
\t * instead of KERN_NOT_SUPPORTED.  iOS 26's libxpc asks this of every
\t * listener peer at check-in; on KERN_NOT_SUPPORTED every service drops
\t * its clients as a "bogus check-in" (cfprefsd, usermanagerd,
\t * containermanagerd ... nothing could talk to anything).
\t */
\tif (!mach_msg_filter_at_least(MACH_MSG_FILTER_CALLBACKS_VERSION_1)) {
\t\tip_mq_unlock_label_put(service_port, &label);
\t\t*filter_policy_id = 0;
\t\treturn KERN_SUCCESS;
\t}

\t/* Port is locked and active */
\tservice_port_sblabel = label.iol_service->ispl_sblabel;
\tif (service_port_sblabel) {
\t\tmach_msg_filter_retain_sblabel_callback(service_port_sblabel);
\t}
\tip_mq_unlock_label_put(service_port, &label);
"""
n = s.count(old)
assert n == 1, "expected exactly 1 match, got %d" % n
s = s.replace(old, new)
open(p, "w").write(s)
print("S62 APPLIED, backup at", p + ".s61d.bak")
