"""Assemble the real ggplot2 result figures into a showcase GIF for the README."""
from PIL import Image
import os

SRC = "/app/docs/figures"
ORDER = [
    "01_sleep_hist.png",
    "02_sleep_wellbeing.png",
    "03_wellbeing_by_quality.png",
    "04_corr_heatmap.png",
    "05_resid_fitted.png",
    "06_qq.png",
]
CANVAS = (1000, 760)
BG = (255, 255, 255)

frames = []
for name in ORDER:
    img = Image.open(os.path.join(SRC, name)).convert("RGB")
    # fit within canvas keeping aspect
    img.thumbnail((CANVAS[0] - 40, CANVAS[1] - 40), Image.LANCZOS)
    canvas = Image.new("RGB", CANVAS, BG)
    x = (CANVAS[0] - img.width) // 2
    y = (CANVAS[1] - img.height) // 2
    canvas.paste(img, (x, y))
    frames.append(canvas)

out = "/app/docs/demo.gif"
frames[0].save(
    out, save_all=True, append_images=frames[1:],
    duration=1800, loop=0, optimize=True,
)
print("GIF written:", out, os.path.getsize(out) // 1024, "KB")
