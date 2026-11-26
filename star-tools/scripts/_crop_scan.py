from PIL import Image
im = Image.open("/mnt/c/ios26/screen-now-full.png")
# 全宽红框区 1400-2500，每 60px 一段放大，找 EXECBGR Metal 行
# 已知: band_c(1400-1750)顶部=launchd panic行; band_a(1750-2050)=846-852.5;
# band_b(2050-2350)=852.6-852.7; band_d(2350-2500)=853.75
# EXECBGR Metal 行时间戳 853.744602 出现在 GPU 段(846-852)之后
# 由于多核乱序，按内容搜：把 2050-2500 全段放大2.5倍一次看
for name, y0, y1 in [("scan1",2110,2350),("scan2",2350,2500)]:
    crop = im.crop((30, y0, 1410, y1))
    crop = crop.resize((int(crop.width*2.5), int(crop.height*2.5)), Image.LANCZOS)
    crop.save(f"/mnt/c/ios26/{name}.png")
    print(name, crop.size)
