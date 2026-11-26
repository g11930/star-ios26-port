#!/bin/bash
F=/mnt/c/ios26/s64-logdump.bin
echo "########## 1. render pipeline: built vs refused ##########"
strings -a "$F" | grep -E "render pipelines: .* built" | sed 's/^.*render pipelines: //' | head -20
echo
echo "########## 2. what is refused (unique reasons) ##########"
strings -a "$F" | grep -E "this render pipeline is refused|is refused:" | sed 's/^.*refused: //' | sort | uniq -c | sort -rn | head -20
echo
echo "########## 3. softpipe capability limits ##########"
strings -a "$F" | grep -iE "softpipe.*(not support|unsupported|does not|missing|cannot)" | sed 's/^.*softpipe/softpipe/' | sort -u | head -25
echo
echo "########## 4. all distinct refusal reasons (full) ##########"
strings -a "$F" | grep -oiE "does not support [A-Za-z0-9_ ]+" | sort | uniq -c | sort -rn | head -25
echo
echo "########## 5. backend=softpipe count / distinct pids ##########"
strings -a "$F" | grep -c "backend=softpipe"
echo
echo "########## 6. did any frame ever reach panel? ##########"
strings -a "$F" | grep "panel rows drawn" | grep -oE "^\S* *[0-9]+ panel rows drawn" | head
strings -a "$F" | grep -c "0 panel rows drawn a frame"
echo -n "nonzero panel rows: "; strings -a "$F" | grep "panel rows drawn" | grep -vc " 0 panel rows drawn"
