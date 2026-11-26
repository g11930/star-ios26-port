#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## A. SPWNRET distribution (error values) ##########"
strings -a "$F" | grep "SPWNRET" | sed 's/STARX SPWNRET //' | sort | uniq -c | sort -rn
echo
echo "########## B. persona type-6 / kpersona msgs ##########"
strings -a "$F" | grep -iE "persona" | grep -viE "SPWNVAL|SPWNADOPT" | head -20
echo
echo "########## C. xpcproxy spawn/exit correlation ##########"
echo -n "loading xpcproxy = "; strings -a "$F" | grep -c "loading /usr/libexec/xpcproxy"
echo -n "P28EXIT xpcproxy = "; strings -a "$F" | grep -c "xpcproxy xstat"
echo -n "unique pids        = "; strings -a "$F" | grep "xpcproxy xstat" | sed 's/.*pid \([0-9]*\).*/\1/' | sort -n -u | wc -l
echo -n "xstat non-zero     = "; strings -a "$F" | grep "xpcproxy xstat" | grep -vc "xstat 0 "
echo
echo "########## D. launchd service-level messages ##########"
strings -a "$F" | grep -iE "com.apple.xpc.launchd" | grep -iE "service|spawn|request|bootstrap|port|lookup|domain" | sed 's/^.*<[A-Za-z]*>: //' | sort | uniq -c | sort -rn | head -25
echo
echo "########## E. display: first panel/fb init lines ##########"
strings -a "$F" | grep -iE "MiniIOMobileFramebuffer|DSI|panel|MIPI|display" | grep -viE "frames in|no row changed|property" | head -25
echo
echo "########## F. render/scene/surface ##########"
strings -a "$F" | grep -iE "render|scene|surface|workspace|FrontBoard|BackBoard" | grep -iE "fail|error|unable|timeout|nil|denied|missing" | head -20
echo
echo "########## G. crash reports ##########"
strings -a "$F" | grep -iE "\.ips|crash report|EXC_|signal [0-9]+|SIGTRAP|abort" | head -20
