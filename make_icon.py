#!/usr/bin/env python3
"""Bold single-emblem app icon for Phỏm & Tá Lả: a completed "phỏm" — three fanned Ace
cards of the same rank (a same-rank meld/"phỏm ngang") spread on a deep maroon/red gradient,
the traditional Vietnamese card-table color. No detailed scene, no busy background — matches
SamLoc's house style of one bold emblem, just a different silhouette and palette so the two
icons read as distinct apps at a glance."""

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#2a0a10")
draw = ImageDraw.Draw(img)

top = (58, 14, 20)
bottom = (18, 4, 7)
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

cream = (250, 247, 238, 255)
red = (176, 24, 34, 255)
black = (30, 26, 24, 255)

try:
    font_rank = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(SIZE * 0.22))
    font_pip = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(SIZE * 0.16))
except OSError:
    font_rank = ImageFont.load_default()
    font_pip = font_rank


def centered_text(d, text, font, cx, cy, fill):
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]), text, font=font, fill=fill)


def make_card(rank, suit, color):
    """One playing card on its own transparent layer, unrotated, centered in the layer."""
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cw, ch = SIZE * 0.40, SIZE * 0.60
    cx, cy = SIZE / 2, SIZE / 2
    box = [cx - cw / 2, cy - ch / 2, cx + cw / 2, cy + ch / 2]
    # soft drop shadow so overlapping cards read as separate layers
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = SIZE * 0.012
    sd.rounded_rectangle([box[0] + off, box[1] + off, box[2] + off, box[3] + off],
                          radius=SIZE * 0.035, fill=(0, 0, 0, 90))
    layer.paste(shadow, (0, 0), shadow)
    d.rounded_rectangle(box, radius=SIZE * 0.035, outline=(20, 14, 12, 255), width=3, fill=cream)
    centered_text(d, rank, font_rank, cx, cy - SIZE * 0.10, color)
    centered_text(d, suit, font_pip, cx, cy + SIZE * 0.14, color)
    # corner pip (top-left) so the fanned cards read as real playing cards
    corner_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(SIZE * 0.075))
    d.text((box[0] + SIZE * 0.03, box[1] + SIZE * 0.02), rank, font=corner_font, fill=color)
    return layer, (cx, cy)


emblem = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

# Three fanned Aces — a completed same-rank "phỏm ngang" (3-card set), the core win emblem.
cards = [
    ("A", "♣", black, -26, (-SIZE * 0.16, SIZE * 0.03)),
    ("A", "♥", red, 0, (0, -SIZE * 0.02)),
    ("A", "♦", red, 26, (SIZE * 0.16, SIZE * 0.03)),
]

for rank, suit, color, angle, offset in cards:
    layer, (cx, cy) = make_card(rank, suit, color)
    rotated = layer.rotate(angle, resample=Image.BICUBIC, expand=False, center=(cx, cy))
    dx, dy = offset
    shifted = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shifted.paste(rotated, (int(dx), int(dy)), rotated)
    emblem = Image.alpha_composite(emblem, shifted)

img = img.convert("RGBA")
img = Image.alpha_composite(img, emblem).convert("RGB")

out_path = "/Users/q/Projects/PhomTaLa/PhomTaLa/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
img.save(out_path)
print("wrote AppIcon.png", img.size, "->", out_path)
