"""Environment art: three parallax layers per area (sky, far, near), a ground tile and
a platform plank. Gradients use ordered (Bayer) dithering for a pixel-art look. All
randomness is seeded, so the art is identical on every build."""
import math
import os
import random
from PIL import Image
from pixel import Canvas, hexc
from palette import P

LW, LH = 320, 180          # one layer, before the 4x scale
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

AREAS = {
    "ledger": {"sky": ("f3ecd9", "e9e0c8"), "far": "d9ceb2", "far_dark": "c4b797", "near": "b8a888", "accent": "bf376e",
               "ground": ("e4dbc3", "cfc4a8", "b8a888"), "plank": ("2b2531", "51485f")},
    "percussion": {"sky": ("2a1b1a", "5a3326"), "far": "3d2620", "far_dark": "2a1a16", "near": "5e3b2a", "accent": "e8905f",
                   "ground": ("8e3f22", "cd6337", "5e2a17"), "plank": ("2b2531", "8a5a36")},
    "wind": {"sky": ("9fd7e6", "e8f4ee"), "far": "8fb9c9", "far_dark": "6f9cb0", "near": "4f8f6a", "accent": "ffffff",
             "ground": ("5e8c4a", "7fb05f", "3d5e31"), "plank": ("2b2531", "b07a4c")},
    "string": {"sky": ("1d1633", "4a3a80"), "far": "2c2350", "far_dark": "1d1738", "near": "2f4a3a", "accent": "c8f7a0",
               "ground": ("3a4a2f", "5a7a44", "243020"), "plank": ("2b2531", "6e56b3")},
    "podium": {"sky": ("1a0f12", "4a1a22"), "far": "7a1f2c", "far_dark": "4e131c", "near": "2b1a14", "accent": "f1c95a",
               "ground": ("6b4426", "9a6a3c", "44291a"), "plank": ("2b2531", "bf993b")},
    "grand": {"sky": ("0c0f24", "2e3366"), "far": "3a4288", "far_dark": "262c5e", "near": "4a52a0", "accent": "f1c95a",
              "ground": ("262a4a", "3e4478", "15182e"), "plank": ("2b2531", "4a52a0")},
}


def lerp_c(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def dither_gradient(c, top, bottom, y0=0, y1=None, steps=6):
    """Vertical gradient quantised into `steps` bands, dithered between neighbours."""
    y1 = y1 or c.h
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1))
        band = t * (steps - 1)
        lo = int(band)
        frac = band - lo
        for x in range(c.w):
            pick = lo + (1 if frac * 16 > BAYER[y % 4][x % 4] else 0)
            c.set(x, y, lerp_c(top, bottom, min(pick, steps - 1) / (steps - 1)))


def ridge(rng, width, base, amp, rough, wrap=True):
    """A tileable height line: sum of sines with random phases (wraps at `width`)."""
    phases = [rng.random() * math.tau for _ in range(4)]
    freqs = [1, 2, 3, 5]
    out = []
    for x in range(width):
        v = 0.0
        for i, f in enumerate(freqs):
            v += math.sin(x / width * math.tau * f + phases[i]) / (i + 1)
        out.append(int(base + v * amp + rng.uniform(-rough, rough)))
    return out


def fill_below(c, heights, col, dark=None):
    for x, h in enumerate(heights):
        for y in range(max(0, h), c.h):
            c.set(x, y, col if not dark or y > h + 2 else dark)


# ------------------------------------------------------------------------ per area
def sky_layer(area, rng):
    a = AREAS[area]
    c = Canvas(LW, LH)
    dither_gradient(c, hexc(a["sky"][0]), hexc(a["sky"][1]))
    if area == "ledger":
        for y in range(18, LH, 14):
            c.line(0, y, LW - 1, y, hexc("b9cde0"))
        c.line(40, 0, 40, LH - 1, hexc("e08aa0"))
    elif area == "percussion":
        for i in range(14):
            x, y = rng.randrange(LW), rng.randrange(LH // 2)
            c.set(x, y, hexc(a["accent"])); c.set(x + 1, y, hexc("f1c95a"))
    elif area == "wind":
        for i in range(7):
            cx, cy = rng.randrange(LW), rng.randrange(20, 90)
            for k in range(5):
                c.ellipse(cx + k * 7 - 14, cy + (k % 2) * 2, 9, 5, hexc("ffffff"))
            c.ellipse(cx, cy + 5, 22, 3, hexc("e1eef0"))
    elif area in ("string", "grand"):
        for i in range(60):
            x, y = rng.randrange(LW), rng.randrange(LH)
            c.set(x, y, hexc("ffffff") if i % 5 else hexc(a["accent"]))
        if area == "grand":
            for i in range(8):
                x, y = rng.randrange(LW), rng.randrange(20, 140)
                c.ellipse(x, y, 2.2, 1.6, hexc("9aa3e0"), rot=-0.4)
                c.line(x + 2, y, x + 2, y - 7, hexc("9aa3e0"))
    elif area == "podium":
        for i in range(5):
            x = 30 + i * 65
            for y in range(0, 110):
                w = int(y * 0.25)
                for dx in range(-w, w + 1):
                    c.blend(x + dx, y, hexc("f1c95a", 26 if (x + dx + y) % 3 else 40))
    return c


def far_layer(area, rng):
    a = AREAS[area]
    c = Canvas(LW, LH)
    col, dark = hexc(a["far"]), hexc(a["far_dark"])
    if area == "percussion":
        top = ridge(rng, LW, 18, 10, 3)
        for x, h in enumerate(top):
            for y in range(0, h):
                c.set(x, y, dark)
        for i in range(16):   # stalactites
            x = rng.randrange(LW); ln = rng.randrange(10, 34)
            for y in range(top[x], top[x] + ln):
                w = max(0, int((1 - (y - top[x]) / ln) * 3))
                for dx in range(-w, w + 1):
                    c.set(x + dx, y, dark)
        fill_below(c, ridge(rng, LW, 128, 16, 2), col, dark)
    elif area == "wind":
        for i in range(5):
            cx, cy = rng.randrange(LW), rng.randrange(70, 120)
            w = rng.randrange(22, 40)
            c.ellipse(cx, cy, w, 5, col)
            c.poly([(cx - w, cy), (cx + w, cy), (cx, cy + w * 0.6)], dark)
        fill_below(c, ridge(rng, LW, 150, 8, 1), col, dark)
    elif area == "string":
        fill_below(c, ridge(rng, LW, 120, 12, 2), dark)
        for i in range(22):   # string-trees: tall trunks strung like instruments
            x = rng.randrange(LW); top = rng.randrange(30, 80)
            c.line(x, top, x, LH - 1, col, width=2)
            c.ellipse(x, top, rng.randrange(8, 14), rng.randrange(6, 10), dark)
            c.line(x + 3, top + 4, x + 3, LH - 1, hexc("9c86de", 90))
    elif area == "podium":
        for x in range(0, LW):
            fold = int(4 * math.sin(x * 0.35))
            for y in range(0, 26 + fold):
                c.set(x, y, col if x % 8 < 5 else dark)
        for side in (0, 1):
            for x in range(0, 46):
                xx = x if side == 0 else LW - 1 - x
                for y in range(0, LH):
                    if (x + int(3 * math.sin(y * 0.2))) % 9 < 6:
                        c.set(xx, y, col if x % 9 < 4 else dark)
        for i in range(3):
            y = 120 + i * 14
            c.rect(60, y, LW - 120, 3, dark)
    elif area == "grand":
        for k in range(5):
            pts = []
            for x in range(LW):
                pts.append(int(70 + k * 9 + 18 * math.sin(x / LW * math.tau)))
            for x, y in enumerate(pts):
                c.set(x, y, col)
        fill_below(c, ridge(rng, LW, 150, 10, 1), dark)
    else:  # ledger: crumpled paper hills
        fill_below(c, ridge(rng, LW, 126, 14, 2), col, dark)
        for i in range(10):
            x, y = rng.randrange(LW), rng.randrange(130, 170)
            c.ellipse(x, y, 5, 3, hexc("f6b3c1"))
    return c


def near_layer(area, rng):
    a = AREAS[area]
    c = Canvas(LW, LH)
    col = hexc(a["near"])
    if area == "percussion":
        for i in range(9):
            x = rng.randrange(LW); h = rng.randrange(14, 40)
            c.poly([(x - 6, LH), (x, LH - h), (x + 6, LH)], col)
        for i in range(3):
            x = rng.randrange(20, LW - 20)
            c.rect(x - 10, LH - 20, 20, 16, hexc("8e3f22"))
            c.ellipse(x, LH - 20, 10, 3, hexc("f3ecd9"))
    elif area == "wind":
        for i in range(40):
            x = rng.randrange(LW); h = rng.randrange(8, 26)
            c.line(x, LH, x + rng.randrange(-2, 3), LH - h, col)
        for i in range(4):
            x = rng.randrange(LW)
            c.rect(x, LH - 60, 5, 60, hexc("7cc8bf"))
            for y in range(LH - 54, LH - 10, 12):
                c.set(x + 2, y, hexc("2a6a66"))
    elif area == "string":
        for i in range(12):
            x = rng.randrange(LW)
            for k in range(5):
                c.line(x, LH, x + (k - 2) * 4, LH - 10 - k % 3 * 4, col)
        for i in range(10):
            x = rng.randrange(LW)
            c.rect(x, LH - 8, 2, 6, hexc("e4dbc3"))
            c.ellipse(x + 1, LH - 9, 4, 2.4, hexc(a["accent"]))
    elif area == "podium":
        for i in range(8):
            x = 20 + i * 40
            c.rect(x, LH - 10, 14, 10, hexc("2b1a14"))
            for y in range(LH - 60, LH - 10):
                w = int((LH - 10 - y) * 0.2)
                for dx in range(-w, w + 1):
                    c.blend(x + 7 + dx, y, hexc("f1c95a", 30 if (dx + y) % 4 else 55))
    elif area == "grand":
        for i in range(30):
            x, y = rng.randrange(LW), rng.randrange(LH)
            c.set(x, y, hexc(a["accent"]))
            c.set(x + 1, y, hexc(a["accent"], 120)); c.set(x - 1, y, hexc(a["accent"], 120))
    else:  # ledger: pencil shavings, a paperclip, eraser crumbs
        for i in range(6):
            x = rng.randrange(LW)
            c.poly([(x, LH - 2), (x + 8, LH - 10), (x + 12, LH - 2)], hexc("d8a36a"))
            c.line(x + 1, LH - 3, x + 10, LH - 3, hexc("bf376e"))
        x = rng.randrange(40, LW - 40)
        for dx in range(22):
            c.set(x + dx, LH - 14, hexc("9e96a3")); c.set(x + dx, LH - 6, hexc("9e96a3"))
        c.line(x, LH - 14, x, LH - 6, hexc("9e96a3")); c.line(x + 22, LH - 14, x + 22, LH - 6, hexc("9e96a3"))
        for i in range(25):
            c.set(rng.randrange(LW), LH - rng.randrange(1, 6), hexc("f6b3c1"))
    return c


def ground_tile(area):
    top, mid, dark = (hexc(h) for h in AREAS[area]["ground"])
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, mid)
    c.rect(0, 0, 16, 3, top)
    for y in range(4, 16, 5):
        off = 0 if (y // 5) % 2 == 0 else 8
        c.line(0, y, 15, y, dark)
        c.line(off, y, off, y + 4, dark)
    c.line(0, 3, 15, 3, dark)
    return c


def plank(area):
    ink, light = (hexc(h) for h in AREAS[area]["plank"])
    c = Canvas(16, 6)
    c.rect(0, 0, 16, 2, ink)
    c.rect(0, 2, 16, 3, light)
    c.rect(0, 5, 16, 1, ink)
    for x in (3, 11):
        c.set(x, 3, ink)
    return c


def build(root, preview_dir=None):
    count = 0
    out_dir = os.path.join(root, "assets", "env")
    os.makedirs(out_dir, exist_ok=True)
    for i, area in enumerate(AREAS):
        rng = random.Random(1000 + i)
        layers = {"sky": sky_layer(area, rng), "far": far_layer(area, rng), "near": near_layer(area, rng),
                  "ground": ground_tile(area), "plank": plank(area)}
        for name, canvas in layers.items():
            img = canvas.image()
            img.save(os.path.join(out_dir, "%s_%s.png" % (area, name)))
            count += 1
        if preview_dir:
            comp = Image.new("RGBA", (LW, LH))
            for name in ("sky", "far", "near"):
                comp.alpha_composite(layers[name].image())
            comp.resize((LW * 3, LH * 3), Image.NEAREST).save(os.path.join(preview_dir, "_env_%s.png" % area))
    return count
