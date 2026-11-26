#!/usr/bin/env python3
p = '/root/star26/s111/work/rootbuild/root/etc/rc.jobs'
open(p, 'w').write(
"/annibale/bin/trialwake\n"
"# star: the port's own triangle, so the panel says whether Metal draws here at all.\n"
"# init runs these lines itself: one program per line, arguments split on blanks.\n"
"/annibale/bin/metal_props on\n"
"/annibale/bin/triangle_app --layer\n")
print(open(p).read())