#!/usr/bin/env python3
"""Add idempotent guard to annibale_goodix_init: iOS26 input.c calls it twice, iOS16 called once."""
p='/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s=open(p,encoding='utf-8').read()
old='''void
annibale_goodix_init(void)
{
\tuint32_t enabled = 0;
\tthread_t thread;
\n\tkern_return_t started;
\tbool parsed;

\tloader_log_line("\\nGOODIX_INIT_ENTERED\\n");'''
# exact match may vary; use a robust anchor
anchor='''void
annibale_goodix_init(void)
{
\tuint32_t enabled = 0;'''
if anchor not in s:
    # find actual
    i=s.find('annibale_goodix_init(void)')
    print('ANCHOR MISS, context:'); print(repr(s[i:i+250])); raise SystemExit(2)
new='''static bool annibale_goodix_inited;   /* iOS26 input.c calls init twice; iOS16 called once */

void
annibale_goodix_init(void)
{
\tuint32_t enabled = 0;'''
s=s.replace(anchor,new,1)
# now add the guard right after the opening brace of the function body
# find the body start after "uint32_t enabled = 0;"
needle='''annibale_goodix_init(void)
{
\tuint32_t enabled = 0;'''
guard='''annibale_goodix_init(void)
{
\tif (annibale_goodix_inited) return;
\tannibale_goodix_inited = true;

\tuint32_t enabled = 0;'''
if needle not in s:
    print('guard needle miss'); raise SystemExit(3)
s=s.replace(needle,guard,1)
open(p,'w',encoding='utf-8').write(s)
print('guard added')
# verify
i=s.find('annibale_goodix_init(void)')
print(s[i-60:i+260])
