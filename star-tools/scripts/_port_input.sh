#!/bin/bash
set -e
K=/root/star26/star-native
cp /mnt/d/桌面/star26-deps/scripts/annibale_input.c $K/bsd/dev/star/annibale_input.c

# 1) the new file joins the build
grep -q 'bsd/dev/star/annibale_input.c' $K/bsd/conf/files || \
  sed -i 's#^bsd/dev/star/annibale_image.c\t\tstandard$#bsd/dev/star/annibale_input.c\tstandard\nbsd/dev/star/annibale_image.c\t\tstandard#' $K/bsd/conf/files

# 2) the stub no longer defines it
python3 - <<'PY'
p = '/root/star26/star-native/bsd/dev/star/star_platform_stubs.c'
s = open(p).read()
old = '''/* The GPU is woken here, where the reference port wakes it too (its input init).
 * It returns at once unless gpu=1 and the GPU's firmware is in the small image. */
void annibale_input_init(void)
{
	annibale_adreno_init();
}
'''
new = '''/* annibale_input_init() now lives in bsd/dev/star/annibale_input.c, which creates
 * /dev/annibale-touch and then wakes the GPU, as the reference port's input init did. */
'''
if old in s:
    s = s.replace(old, new, 1)
    s = s.replace('extern void annibale_adreno_init(void);\n\n', '', 1)
    open(p, 'w').write(s)
    print('stub cleaned')
else:
    print('stub pattern not found (checking)')
PY
grep -n 'annibale_input' $K/bsd/conf/files
grep -rn 'annibale_input_init' $K/bsd/dev/star/*.c | head
</>
