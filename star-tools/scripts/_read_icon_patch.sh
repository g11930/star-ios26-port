#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "############ 60..160"
sed -n '60,160p' "$F"
echo
echo "############ 930..960"
sed -n '930,960p' "$F"
echo
echo "############ 1100..1213"
sed -n '1100,1213p' "$F"
