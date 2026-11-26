#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "############ 1. BACKLIGHT / DISPLAY chain ############"
strings -a "$F" | grep -iE "backlight|dsi|panel|framebuffer|IOMobileFrameBuffer|fb_flip|present|swap|display.*ready|AdoptedDisplay" | grep -viE "BrightnessSystem property|FreezeBrightness" | head -50
echo
echo "############ 2. process count / boot progress ############"
strings -a "$F" | grep -E "proc count|processes|Early boot complete|Cache sent|Continuing system boot" | head -10
echo
echo "############ 3. xpcproxy context: launchd complaints ############"
strings -a "$F" | grep -iE "xpcproxy|posix_spawn|failed to spawn|could not exec|XPC_SERVICE|bootstrap.*fail|no mach port|persistent service" | head -40
echo
echo "############ 4. SpringBoard / backboardd state ############"
strings -a "$F" | grep -iE "SpringBoard|backboardd" | grep -iE "launch|start|ready|wait|block|fail|scene|surface|frame" | head -30
