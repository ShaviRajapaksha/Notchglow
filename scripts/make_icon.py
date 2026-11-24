#!/usr/bin/env python3
"""
Generates the NotchGlow app icon: a glowing cyan-to-pink waveform on a dark tile.

  python3 scripts/make_icon.py

Writes:
  Resources/AppIcon.icns        (used by build_app.sh)
  Resources/AppIcon.iconset/    (the same artwork as PNGs; `iconutil -c icns` can rebuild the .icns on a Mac)
  Resources/AppIcon-1024.png    (marketing / website artwork)

Only needs Pillow (pip install pillow). The .icns container is written directly, so no macOS tools are required.
"""
import io
import os
import struct
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "Resources")

CANVAS = 2048           # supersampled working size (final art is 1024)
U = CANVAS / 1024.0     # 1 design unit (on a 1024 grid) in working pixels

CYAN, VIOLET, PINK = (56, 219, 255), (158, 107, 255), (255, 92, 184)


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(3))


def gradient_color(t):
    """0 = center (cyan) ... 1 = edge (pink), like the app's default gradient."""
    return mix(CYAN, VIOLET, t * 2) if t < 0.5 else mix(VIOLET, PINK, (t - 0.5) * 2)


def squircle_mask(size, half, n=5.0):
    """macOS-style continuous-corner rounded square (superellipse), centered on the canvas."""
    import math
    cx = cy = size / 2
    pts = []
    steps = 720
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        x = cx + half * (abs(c) ** (2 / n)) * (1 if c >= 0 else -1)
        y = cy + half * (abs(s) ** (2 / n)) * (1 if s >= 0 else -1)
        pts.append((x, y))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    return mask


def vertical_gradient(size, top, bottom):
    w, h = size
    grad = Image.linear_gradient("L").resize((w, h))
    return Image.composite(Image.new("RGB", (w, h), bottom), Image.new("RGB", (w, h), top), grad)


def render(bar_count, bar_w, gap, heights, center_y):
    """Renders the 1024x1024 icon artwork for the given waveform layout (all values in 1024-grid units)."""
    S = CANVAS
    tile_half = 412 * U
    tile = squircle_mask(S, tile_half)

    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # Soft drop shadow under the tile.
    shadow = tile.filter(ImageFilter.GaussianBlur(26 * U))
    shadow = ImageChops.offset(shadow, 0, int(18 * U))
    shadow_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow_layer.putalpha(shadow.point(lambda a: int(a * 0.55)))
    canvas = Image.alpha_composite(canvas, shadow_layer)

    # Tile background: deep charcoal with a violet bloom behind the waveform.
    bg = vertical_gradient((S, S), (30, 27, 48), (7, 7, 12)).convert("RGBA")
    bloom = ImageOps.invert(Image.radial_gradient("L")).resize((int(900 * U), int(900 * U)))
    bloom_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bloom_color = Image.new("RGBA", bloom.size, (120, 80, 255, 0))
    bloom_color.putalpha(bloom.point(lambda a: int(a * 0.42)))
    bloom_layer.paste(bloom_color, (int(S / 2 - 450 * U), int(center_y * U - 450 * U)), bloom_color)
    bg = Image.alpha_composite(bg, bloom_layer)
    tile_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    tile_layer.paste(bg, (0, 0), tile)
    canvas = Image.alpha_composite(canvas, tile_layer)

    # Waveform bars (colored by distance from the center, like the app).
    bars = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    total_w = bar_count * bar_w + (bar_count - 1) * gap
    x = 512 - total_w / 2
    mid = (bar_count - 1) / 2
    for i in range(bar_count):
        h = heights[i]
        color = gradient_color(abs(i - mid) / mid if mid else 0)
        x0, x1 = int(x * U), int((x + bar_w) * U)
        y0, y1 = int((center_y - h / 2) * U), int((center_y + h / 2) * U)
        bw, bh = x1 - x0, y1 - y0
        top = tuple(min(255, int(c + (255 - c) * 0.40)) for c in color)
        fill = vertical_gradient((bw, bh), top, color)
        mask = Image.new("L", (bw, bh), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, bw - 1, bh - 1), radius=bw // 2, fill=255)
        bars.paste(fill, (x0, y0), mask)
        x += bar_w + gap

    # Glow = two blurred copies of the bars underneath the crisp bars.
    wide = bars.filter(ImageFilter.GaussianBlur(46 * U))
    wide.putalpha(wide.getchannel("A").point(lambda a: int(min(255, a * 1.1))))
    tight = bars.filter(ImageFilter.GaussianBlur(16 * U))
    glow = Image.alpha_composite(wide, tight)
    glow_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    glow_layer.paste(glow, (0, 0), tile)
    canvas = Image.alpha_composite(canvas, glow_layer)
    bars_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bars_layer.paste(bars, (0, 0), tile)
    canvas = Image.alpha_composite(canvas, bars_layer)

    # Glass highlight across the top of the tile, and a hairline rim light.
    gloss = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    ramp = Image.linear_gradient("L").transpose(Image.FLIP_TOP_BOTTOM).resize((S, int(S * 0.5)))
    full = Image.new("L", (S, S), 0)
    full.paste(ramp.point(lambda a: int(a * 0.10)), (int(0), int(S * 0.5 - tile_half) if False else int(S / 2 - tile_half)))
    gloss.putalpha(ImageChops.multiply(full, tile))
    canvas = Image.alpha_composite(canvas, gloss)

    eroded = tile.filter(ImageFilter.MinFilter(2 * int(3 * U) + 1))
    rim = ImageChops.subtract(tile, eroded)
    rim_layer = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    rim_layer.putalpha(rim.point(lambda a: int(a * 0.16)))
    canvas = Image.alpha_composite(canvas, rim_layer)

    return canvas.resize((1024, 1024), Image.LANCZOS)


def detailed():
    return render(9, 48, 30, [170, 290, 410, 530, 640, 530, 410, 290, 170], 512)


def simple():
    # Fewer, bolder bars so the icon stays readable at 16 to 64 px.
    return render(5, 88, 46, [220, 400, 620, 400, 220], 512)


ICNS_TYPES = [
    # (type code, pixel size, use the simple artwork)
    ("icp4", 16, True), ("icp5", 32, True), ("icp6", 64, True),
    ("ic07", 128, False), ("ic08", 256, False), ("ic09", 512, False), ("ic10", 1024, False),
    ("ic11", 32, True), ("ic12", 64, True), ("ic13", 256, False), ("ic14", 512, False),
]

ICONSET = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]


def png_bytes(img):
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    return buf.getvalue()


def main():
    art_detail, art_simple = detailed(), simple()

    def at(size, use_simple):
        src = art_simple if use_simple else art_detail
        return src.resize((size, size), Image.LANCZOS)

    os.makedirs(RES, exist_ok=True)
    art_detail.save(os.path.join(RES, "AppIcon-1024.png"))

    iconset_dir = os.path.join(RES, "AppIcon.iconset")
    os.makedirs(iconset_dir, exist_ok=True)
    for name, size in ICONSET:
        at(size, size <= 64).save(os.path.join(iconset_dir, name))

    entries = b""
    for code, size, use_simple in ICNS_TYPES:
        data = png_bytes(at(size, use_simple))
        entries += code.encode("ascii") + struct.pack(">I", len(data) + 8) + data
    icns = b"icns" + struct.pack(">I", len(entries) + 8) + entries
    with open(os.path.join(RES, "AppIcon.icns"), "wb") as f:
        f.write(icns)
    print(f"Wrote Resources/AppIcon.icns ({len(icns) // 1024} KB), AppIcon.iconset/ and AppIcon-1024.png")


if __name__ == "__main__":
    sys.exit(main())
