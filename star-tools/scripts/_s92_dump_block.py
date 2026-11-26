PATH = '/root/star26/star-native/bsd/kern/mach_loader.c'
src = open(PATH).read()
i = src.find('result->csflags &= ~CS_VALID')
print(repr(src[i-700:i+100]))
