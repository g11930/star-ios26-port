#!/bin/bash
F=/root/star26/star-native/iokit/Kernel/MiniIOMobileFramebuffer.cpp
echo "=== presenterMain + presenter ==="
sed -n "/^IOMobileFramebuffer::presenterMain/,/^}/p" "$F"
echo "--- presenter() ---"
sed -n "/^IOMobileFramebuffer::presenter(void)/,/^}/p" "$F"
echo "=== present() full ==="
sed -n "/^IOMobileFramebuffer::present(const uint8_t \* swap)/,/^}/p" "$F"
