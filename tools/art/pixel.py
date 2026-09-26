"""A tiny pixel-art canvas for generating the game's sprites.

Coordinates are pixels; (0, 0) is top-left. Colours are (r, g, b, a) tuples.
Shapes are filled first, then outline() wraps everything in a 1 px ink edge and
rim() adds a highlight on top-left edges, which is what gives the sprites their
chunky, cute look.
"""
import math
from PIL import Image

CLEAR = (0, 0, 0, 0)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[CLEAR for _ in range(w)] for _ in range(h)]

    # ------------------------------------------------------------------ basics
    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if self.inside(x, y):
            self.px[y][x] = c

    def blend(self, x, y, c):
        """Mix colour c (using its alpha) over whatever is already there."""
        x, y = int(round(x)), int(round(y))
        if not self.inside(x, y):
            return
        base = self.px[y][x]
        a = c[3] / 255.0
        if base[3] == 0:
            self.px[y][x] = c
            return
        self.px[y][x] = (int(base[0] + (c[0] - base[0]) * a), int(base[1] + (c[1] - base[1]) * a),
                         int(base[2] + (c[2] - base[2]) * a), max(base[3], c[3]))

    def get(self, x, y):
        return self.px[y][x] if self.inside(x, y) else CLEAR

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def line(self, x0, y0, x1, y1, c, width=1):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            for ox in range(width):
                self.set(x0 + ox, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, c, rot=0.0):
        cs, sn = math.cos(rot), math.sin(rot)
        r = int(max(rx, ry)) + 2
        for y in range(int(cy) - r, int(cy) + r + 2):
            for x in range(int(cx) - r, int(cx) + r + 2):
                px, py = x + 0.5 - cx, y + 0.5 - cy
                u = px * cs + py * sn
                v = -px * sn + py * cs
                if (u / rx) ** 2 + (v / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def circle(self, cx, cy, r, c):
        self.ellipse(cx, cy, r, r, c)

    def poly(self, pts, c):
        """Filled polygon (even-odd), pixel centres."""
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            cy = y + 0.5
            xs = []
            for i in range(len(pts)):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
                if (y0 <= cy < y1) or (y1 <= cy < y0):
                    xs.append(x0 + (cy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                for x in range(int(math.ceil(a - 0.5)), int(math.floor(b - 0.5)) + 1):
                    self.set(x, y, c)

    # ------------------------------------------------------------------ finishing
    def outline(self, c, diagonal=False):
        """1 px edge around every filled pixel."""
        filled = [[self.px[y][x][3] > 0 for x in range(self.w)] for y in range(self.h)]
        n = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            n += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        for y in range(self.h):
            for x in range(self.w):
                if filled[y][x]:
                    continue
                for dx, dy in n:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and filled[yy][xx]:
                        self.px[y][x] = c
                        break

    def rim(self, body, light):
        """Pixels of colour `body` on a top or left edge (the neighbour isn't `body`) get `light`."""
        out = [row[:] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] == body and (self.get(x, y - 1) != body or self.get(x - 1, y) != body):
                    out[y][x] = light
        self.px = out

    def replace(self, a, b):
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] == a:
                    self.px[y][x] = b

    def tint_all(self, c, keep=()):
        """Every opaque pixel becomes c (used for flash frames), except colours in keep."""
        for y in range(self.h):
            for x in range(self.w):
                p = self.px[y][x]
                if p[3] > 0 and p not in keep:
                    self.px[y][x] = c

    def flip(self):
        self.px = [list(reversed(row)) for row in self.px]
        return self

    def shift(self, dx, dy):
        out = [[CLEAR for _ in range(self.w)] for _ in range(self.h)]
        for y in range(self.h):
            for x in range(self.w):
                xx, yy = x + dx, y + dy
                if 0 <= xx < self.w and 0 <= yy < self.h:
                    out[yy][xx] = self.px[y][x]
        self.px = out
        return self

    def paste(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                c = other.px[y][x]
                if c[3] > 0:
                    self.set(ox + x, oy + y, c)

    def image(self):
        img = Image.new("RGBA", (self.w, self.h))
        img.putdata([c for row in self.px for c in row])
        return img


def strip(frames):
    """Frames side by side, left to right."""
    w, h = frames[0].w, frames[0].h
    img = Image.new("RGBA", (w * len(frames), h))
    for i, f in enumerate(frames):
        img.paste(f.image(), (i * w, 0))
    return img


# ---------------------------------------------------------------------- shared face parts
def eyes(c, x, y, pal, gap=3, tall=2, pupil=None, look=1, sleepy=False, angry=False):
    """Two cute eyes: white sclera, dark pupil toward `look`, a 1 px sparkle.
    (x, y) is the top-left of the left eye."""
    pupil = pupil or pal["eye_dark"]
    for i, ex in enumerate((x, x + gap)):
        if sleepy:
            c.line(ex, y + tall - 1, ex + 1, y + tall - 1, pupil)
            continue
        c.rect(ex, y, 2, tall, pal["eye"])
        px = ex + (1 if look > 0 else 0)
        c.rect(px, y + tall - 2 if tall >= 3 else y + tall - 1, 1, 2 if tall >= 3 else 1, pupil)
        c.set(ex + (0 if look > 0 else 1), y, pal["sparkle"])
        if angry:
            # Brows slant down toward the middle of the face.
            if i == 0:
                c.set(ex, y - 2, pal["brow"])
                c.set(ex + 1, y - 1, pal["brow"])
            else:
                c.set(ex, y - 1, pal["brow"])
                c.set(ex + 1, y - 2, pal["brow"])


def blush(c, x, y, pal):
    c.set(x, y, pal["blush"])
    c.set(x + 1, y, pal["blush_soft"])
