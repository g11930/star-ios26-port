#!/bin/bash
# Compare Mini display components between P-series source and star-native tree
A=/root/star26/hackios-xnu-kernel/xnu/files/iokit/Kernel
B=/root/star26/star-native/iokit/Kernel
for f in MiniIOMobileFramebuffer.cpp MiniIOSurface.cpp MiniIOSurface.h MiniDrivers.h \
         MiniFramebufferDim.inc MiniFramebufferFlip.inc MiniFramebufferUserClient.inc \
         GenericARMPE.cpp AnnibaleGPU.cpp AnnibaleGPUMemory.inc AnnibaleGPUSubmit.inc \
         MiniFramebufferDCS.inc MiniFramebufferPacing.inc MiniFramebufferRows.inc \
         MiniFramebufferScale.h MiniFramebufferSwap.h MiniIOSurfaceABI.h MiniIOSurfaceABI.inc \
         MiniIOSurfaceUserClient.inc MiniIOSurfaceValues.inc; do
	if cmp -s "$A/$f" "$B/$f"; then
		echo "SAME  $f"
	else
		echo "DIFF  $f ($(diff "$A/$f" "$B/$f" | wc -l) diff-lines)"
	fi
done
echo === missing in star-native ===
for f in MiniAppleARMBacklight.cpp MiniAppleKeyStore.cpp MiniIONetworkStack.cpp AnnibaleBT.cpp AnnibaleBattery.cpp AnnibaleWLAN.cpp; do
	[ -f "$B/$f" ] || echo "MISSING  $f"
done
