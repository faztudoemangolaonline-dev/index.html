from pathlib import Path
from PIL import Image, ImageDraw
import sys

ROOT = Path(__file__).resolve().parents[1]
SIZE = 512
RED = (215, 25, 32, 255)
GOLD = (255, 201, 40, 255)
WHITE = (255, 255, 255, 255)
DARK = (10, 11, 15, 255)

def draw_mark(size, background=True):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    m = int(size * .055)
    if background:
        d.rounded_rectangle((m, m, size-m, size-m), radius=int(size*.22),
                            fill=DARK, outline=GOLD, width=max(2, int(size*.018)))
        d.rounded_rectangle((m+3, m+3, size-m-3, int(size*.42)),
                            radius=int(size*.2), fill=RED)
    # TV body
    x0, y0, x1, y1 = int(size*.19), int(size*.31), int(size*.81), int(size*.75)
    d.line((int(size*.39), int(size*.25), int(size*.48), int(size*.14)), fill=GOLD, width=max(3,int(size*.025)))
    d.line((int(size*.61), int(size*.25), int(size*.52), int(size*.14)), fill=GOLD, width=max(3,int(size*.025)))
    d.rounded_rectangle((x0,y0,x1,y1), radius=int(size*.09), outline=GOLD, width=max(4,int(size*.035)))
    # Play triangle
    cx, cy = int(size*.51), int(size*.53)
    d.polygon([(int(size*.45),int(size*.42)),(int(size*.45),int(size*.64)),(int(size*.63),cy)], fill=WHITE)
    d.rounded_rectangle((int(size*.34),int(size*.79),int(size*.66),int(size*.83)),
                        radius=max(2,int(size*.02)), fill=GOLD)
    return im

def main():
    mode = sys.argv[1] if len(sys.argv)>1 else "android"
    if mode == "android":
        base = ROOT/"android/app/src/main/res"
        for density, px in {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}.items():
            folder=base/f"mipmap-{density}"
            folder.mkdir(parents=True,exist_ok=True)
            draw_mark(px,True).save(folder/"ic_launcher.png",optimize=True)
        anydpi=base/"mipmap-anydpi-v26"
        anydpi.mkdir(parents=True,exist_ok=True)
        (anydpi/"ic_launcher.xml").write_text('''<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>''')
        drawable=base/"drawable"
        drawable.mkdir(parents=True,exist_ok=True)
        draw_mark(432,False).save(drawable/"ic_launcher_foreground.png",optimize=True)
        values=base/"values"
        values.mkdir(parents=True,exist_ok=True)
        (values/"ic_launcher_background.xml").write_text('''<resources><color name="ic_launcher_background">#090A0D</color></resources>''')
        draw_mark(512,True).save(ROOT/"faz-tudo-iptv-icon.png",optimize=True)
        banner=Image.new("RGBA",(320,180),DARK)
        bd=ImageDraw.Draw(banner)
        bd.rectangle((0,0,12,180),fill=RED)
        mark=draw_mark(132,True)
        banner.alpha_composite(mark,(24,24))
        bd.text((174,54),"FAZ TUDO",fill=WHITE)
        bd.text((174,80),"IPTV",fill=GOLD)
        bd.text((174,106),"TECNOLOGIA",fill=WHITE)
        banner.save(drawable/"tv_banner.png",optimize=True)
    elif mode == "windows":
        icon=ROOT/"windows/runner/resources/app_icon.ico"
        icon.parent.mkdir(parents=True,exist_ok=True)
        draw_mark(256,True).save(icon,format="ICO",sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
    else:
        raise SystemExit("Use android or windows")

if __name__ == "__main__":
    main()
