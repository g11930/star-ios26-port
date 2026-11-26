#!/bin/bash
grep -nE "iPhoneOS.sdk|sdk/System|sys-root|ln -s|SDK|CoreFoundation" /root/star26/hackios-xnu-kernel/xnu-deps/setup.sh | head -40
