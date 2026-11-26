#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
ls -la --time-style=+%H:%M:%S "$K"
strings -a "$K" | grep -c 'the volume on INCOMING becomes the root'
strings -a "$K" | grep -F 'the volume on INCOMING' | head -3
strings -a "$K" | grep -F 'star: %s is the root now' | head -3
