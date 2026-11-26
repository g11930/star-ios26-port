#!/bin/bash
# Make a shim include dir containing ONLY ptrauth.h (not Availability.h which breaks CF headers)
mkdir -p /tmp/iconfill_inc
ln -sf /root/star26/star-native/EXTERNAL_HEADERS/ptrauth.h /tmp/iconfill_inc/ptrauth.h
ls -la /tmp/iconfill_inc
