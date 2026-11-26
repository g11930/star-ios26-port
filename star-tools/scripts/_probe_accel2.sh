#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "== 330-410 =="
sed -n '330,412p' "$F"
