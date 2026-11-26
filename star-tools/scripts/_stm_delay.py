#!/usr/bin/env python3
"""Delay STM touch init until first touch_write (after ignition), avoiding boot-time RPMh contention."""
p='/root/star26/star-native/bsd/dev/star/annibale_input.c'
s=open(p,encoding='utf-8').read()
bak=p+'.s194-pre-delay.bak'
import os
if not os.path.exists(bak): open(bak,'w',encoding='utf-8').write(s)
old='''\tannibale_goodix_init();          /* boot-arg touchscreen=1: the FTS touch screen */
\tannibale_adreno_init();'''
new='''\t/* DELAYED: STM touch init runs from touch_write() (after ignition).
\t * Starting it here contends with launchd preboot on RPMh and trapped the boot. */
\tannibale_adreno_init();'''
if old not in s:
    print('ANCHOR MISS'); print(repr(s[s.find('annibale_goodix_init();'):][:200])); raise SystemExit(2)
s=s.replace(old,new,1)
open(p,'w',encoding='utf-8').write(s)
print('delayed init; remaining calls:')
for i,l in enumerate(s.split('\n')):
    if 'annibale_goodix_init' in l: print(' ',i+1,l.strip())
