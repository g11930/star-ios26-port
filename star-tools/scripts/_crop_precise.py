from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
# band_d = y2350-2500 显示4行(852.717,852.717,852.718,853.754402)
# EXECBGR 853.744602 在 853.754402 上一行 => y ~ 2440 附近
# 精确裁 2410-2485，放大3倍
crop = im.crop((30, 2400, 1410, 2490))
crop = crop.resize((int(crop.width * 2.6), int(crop.height * 2.6)), Image.LANCZOS)
crop.save("/mnt/c/ios26/band_precise.png")
print("band_precise", crop.size)
