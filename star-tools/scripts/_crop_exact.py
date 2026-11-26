from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
# EXECBGR 852.544602 紧接 852.543803 之后，band_a(1750-2050)底部
# 精确覆盖 2010-2060，放大4倍
crop = im.crop((30, 2005, 1410, 2065))
crop = crop.resize((int(crop.width * 4), int(crop.height * 4)), Image.LANCZOS)
crop.save("/mnt/c/ios26/band_exact.png")
print("band_exact", crop.size)
