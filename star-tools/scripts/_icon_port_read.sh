#!/bin/bash
echo "########## WARSAW-REF full-provider fallback (285-420) ##########"
sed -n '285,420p' /root/star26/warsaw-ref/userland/src/inject_sb26_airdrop.inc
echo
echo "########## WARSAW-REF call sites (1095-1120, 1795-1815, 1865-1880) ##########"
sed -n '1095,1120p' /root/star26/warsaw-ref/userland/src/inject_sb26.c
echo "----"
sed -n '1795,1815p' /root/star26/warsaw-ref/userland/src/inject_sb26.c
echo "----"
sed -n '1865,1880p' /root/star26/warsaw-ref/userland/src/inject_sb26.c
