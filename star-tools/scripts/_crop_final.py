from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
# 852.543803 在 band_a(y1750-2050) 底部, 852.598 在 band_b(y2050-2350) 顶部
# EXECBGR 852.544602 紧接 852.543803 之后 => y ~ 2045-2075
crop = im.crop((30, 2035, 1410, 2115))
crop = crop.resize((int(crop.width * 2.7), int(crop.height * 2.7)), Image.LANCZOS)
crop.save("/mnt/c/ios26/band_execbgr.png")
print("band_execbgr", crop.size)
