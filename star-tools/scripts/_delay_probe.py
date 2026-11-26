#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()
s = s.replace('struct timespec wait = { 20, 0 };', 'struct timespec wait = { 75, 0 };')
s = s.replace('goodix: thread up, probing in 20 s', 'goodix: thread up, probing in 75 s')
open(p, 'w').write(s)
print('delay set to 75 s:', 'wait = { 75, 0 }' in s)
