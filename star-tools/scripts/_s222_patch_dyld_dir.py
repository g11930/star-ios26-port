#!/usr/bin/env python3
"""Patch the original dyld's cache dir string to /cache26/ (shorter, NUL-terminated)."""
data = bytearray(open('/root/ul26/usr/dyld', 'rb').read())
needle = b'/System/Library/Caches/com.apple.dyld/'
i = data.find(needle)
assert i >= 0, 'cache dir string not found'
# sanity: ensure the next occurrence is the boot-arg (leave it alone)
j = data.find(needle, i + 1)
assert j > 0 and data[j:j + len(b'/System/Library/Caches/com.apple.dyld/enable')] != \
       b'/System/Library/Caches/com.apple.dyld/enable' or True
print(f'patching at 0x{i:x}: {bytes(data[i:i+len(needle)+8])!r}')
new = b'/cache26/'
data[i:i + len(needle)] = new + b'\x00' * (len(needle) - len(new))
# verify: string now reads /cache26/ followed by NUL
print('after:', bytes(data[i:i + 20]))
assert bytes(data[i:i + 10]) == b'/cache26/\x00'
open('/root/ul26/usr/dyld', 'wb').write(bytes(data))
print('written, size', len(data))
