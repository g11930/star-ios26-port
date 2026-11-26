PATH = '/root/star26/s92/parts/cmdline'
data = open(PATH, 'rb').read()
old = b'star_sbmetal=1'
assert old in data, 'anchor missing'
new = b'star_sbmetal=1 star_cs_probe=1 star_cs_keep_valid=1'
data = data.replace(old, new, 1)
open(PATH, 'wb').write(data)
print('CMDLINE OK, len =', len(data))
print(data.decode().replace('\x00', '<NUL>'))
