#!/bin/bash
cd /root/star26/star-native || exit 1
echo "===== A) ubc_subr.c 5600-5720 (signature validation + mac hook) ====="
sed -n '5600,5720p' bsd/kern/ubc_subr.c
echo
echo "===== B) ubc_subr.c 4040-4115 (blob flags init) ====="
sed -n '4040,4115p' bsd/kern/ubc_subr.c
echo
echo "===== C) ubc_subr.c 720-910 (entitlement CS_VALID checks) ====="
sed -n '720,760p' bsd/kern/ubc_subr.c
echo
echo "===== D) security/mac_vfs.c 1316-1345 ====="
sed -n '1310,1345p' security/mac_vfs.c
echo
echo "===== E) mac_framework.h stub shape ====="
sed -n '500,530p' security/mac_framework.h
echo
echo "===== DONE ====="
