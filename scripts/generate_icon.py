#!/usr/bin/env python3
"""
Generate Y2K icon: hot-pink bg, cream heart (front) + lime heart (back, offset).
Outputs icon_source.png (full icon) and icon_source_fg.png (adaptive foreground).
Run from the project root: python3 scripts/generate_icon.py
"""

import math
from PIL import Image, ImageDraw
import os, sys
if not os.path.exists("pubspec.yaml"):
    sys.exit("Error: run from the Flutter project root (pubspec.yaml not found here)")

RENDER = 4096   # super-sample at 4x for crisp downscaled edges
OUTPUT = 1024


def cubic_bezier(p0, p1, p2, p3, steps=80):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts


# Heart path segments from SVG: M36 57 C... at 72x62 viewBox
HEART_SEGS = [
    ((36, 57), (36, 57), (2, 36),  (2, 16)),
    ((2,  16), (2,  8),  (8,  2),  (17, 2)),
    ((17, 2),  (23, 2),  (29, 6),  (36, 13)),
    ((36, 13), (43, 6),  (49, 2),  (55, 2)),
    ((55, 2),  (64, 2),  (70, 8),  (70, 16)),
    ((70, 16), (70, 36), (36, 57), (36, 57)),
]


def heart_polygon(cx, cy, width):
    """Polygon for a heart centered at (cx, cy) with given pixel width."""
    sx = width / 72
    ox = cx - width / 2
    oy = cy - (62 * sx) * 0.42   # visual center sits ~42% from top of bounding box
    pts = []
    for seg in HEART_SEGS:
        for p in cubic_bezier(*seg)[:-1]:   # drop last point (=first of next seg)
            pts.append((ox + p[0] * sx, oy + p[1] * sx))
    return pts


def inset_polygon(pts, amount):
    """Pull each point inward toward the centroid by `amount` pixels."""
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    result = []
    for px, py in pts:
        dx, dy = cx - px, cy - py
        dist = math.hypot(dx, dy)
        move = min(amount, dist * 0.9)
        r = move / dist if dist > 0 else 0
        result.append((px + dx * r, py + dy * r))
    return result


def draw_heart(draw, cx, cy, width, fill_rgb, outline_rgb, stroke_px):
    outer = heart_polygon(cx, cy, width)
    inner = inset_polygon(outer, stroke_px)
    draw.polygon(outer, fill=outline_rgb)
    draw.polygon(inner, fill=fill_rgb)


def star4_points(x, y, r):
    """8-point list for a 4-point star centered at (x,y) with outer radius r."""
    pts = []
    for i in range(8):
        angle = math.pi / 4 * i - math.pi / 2
        radius = r if i % 2 == 0 else r * 0.28
        pts.append((x + radius * math.cos(angle), y + radius * math.sin(angle)))
    return pts


# Palette
PINK  = (255, 94,  168, 255)   # #FF5EA8  background
LIME  = (198, 255, 61,  255)   # #C6FF3D  back heart fill
CREAM = (255, 245, 225, 255)   # #FFF5E1  front heart fill
INK   = (14,  14,  18,  255)   # #0E0E12  stroke


def render_icon(cx_frac, cy_frac, heart_w_frac, offset_frac, size):
    img = Image.new("RGBA", (size, size), PINK)
    draw = ImageDraw.Draw(img)

    heart_w = int(heart_w_frac * size)
    stroke  = int(0.024 * size)
    offset  = int(offset_frac * size)

    fg_cx = int(cx_frac * size)
    fg_cy = int(cy_frac * size)
    bg_cx = fg_cx + offset
    bg_cy = fg_cy + offset

    # Lime heart (back layer)
    draw_heart(draw, bg_cx, bg_cy, heart_w, LIME[:3], INK[:3], stroke)
    # Cream heart (front layer)
    draw_heart(draw, fg_cx, fg_cy, heart_w, CREAM[:3], INK[:3], stroke)

    # Corner star decorations
    g = int(0.045 * size)
    for (sx, sy, r_frac, alpha) in [
        (g * 2.5,        g * 2.2,        0.70, 115),
        (size - g * 4,   size - g * 1.8, 0.50,  89),
        (size - g * 2.5, g * 2.0,        0.45,  77),
    ]:
        r = int(g * r_frac)
        color = INK[:3] + (alpha,)
        draw.polygon(star4_points(sx, sy, r), fill=color)

    return img


if __name__ == "__main__":
    # Full icon
    full_render = render_icon(
        cx_frac=0.39, cy_frac=0.40,
        heart_w_frac=0.55, offset_frac=0.215,
        size=RENDER,
    )
    full_out = full_render.resize((OUTPUT, OUTPUT), Image.LANCZOS).convert("RGB")
    full_out.save("icon_source.png")
    print(f"✓ icon_source.png  ({OUTPUT}x{OUTPUT})")

    # Adaptive icon foreground (transparent background, hearts in center 66% safe zone)
    FG_RENDER = 4096
    FG_OUTPUT = OUTPUT  # 1024
    fg_scale = FG_RENDER / FG_OUTPUT

    fg_img = Image.new("RGBA", (FG_RENDER, FG_RENDER), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(fg_img)

    heart_w_fg = int(0.45 * FG_RENDER)
    stroke_fg  = int(0.024 * FG_RENDER)
    off_fg     = int(0.14 * FG_RENDER)
    cx_fg      = int(0.42 * FG_RENDER)
    cy_fg      = int(0.43 * FG_RENDER)

    draw_heart(draw_fg, cx_fg + off_fg, cy_fg + off_fg, heart_w_fg, LIME[:3],  INK[:3], stroke_fg)
    draw_heart(draw_fg, cx_fg,          cy_fg,           heart_w_fg, CREAM[:3], INK[:3], stroke_fg)

    fg_out = fg_img.resize((FG_OUTPUT, FG_OUTPUT), Image.LANCZOS)
    fg_out.save("icon_source_fg.png")
    print(f"✓ icon_source_fg.png ({FG_OUTPUT}x{FG_OUTPUT}, transparent bg)")
