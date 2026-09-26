"""The five bosses, drawn large. Frames: idle x2, windup, hurt."""
import math
from pixel import Canvas, eyes
from palette import P

FRAMES = ["idle_a", "idle_b", "windup", "hurt"]
ANIMATIONS = {"idle": ([0, 1], 2.5), "windup": ([2], 1.0), "hurt": ([3], 1.0)}


def _bob(pose):
    return {"idle_a": 0, "idle_b": -1, "windup": 1, "hurt": 0}[pose]


def _big_eyes(c, x, y, pose, gap=6):
    pupil = P["hush_glow"] if pose == "windup" else P["hush_eye"]
    if pose == "hurt":
        for dx in (0, gap):
            c.line(x + dx, y, x + dx + 2, y + 2, P["outline"]); c.line(x + dx + 2, y, x + dx, y + 2, P["outline"])
        return
    eyes(c, x, y, dict(P), gap=gap, tall=3, pupil=pupil, angry=True)
    c.rect(x, y, 3, 3, P["eye"]); c.rect(x + gap, y, 3, 3, P["eye"])
    c.rect(x + 1, y + 1, 2, 2, pupil); c.rect(x + gap + 1, y + 1, 2, 2, pupil)
    c.set(x, y, P["sparkle"]); c.set(x + gap, y, P["sparkle"])
    for dx, sl in ((0, 1), (gap, -1)):
        c.line(x + dx, y - 2 + (0 if sl > 0 else 1), x + dx + 2, y - 2 + (1 if sl > 0 else 0), P["brow"])


def timpani(pose):
    W, H = 44, 40
    c = Canvas(W, H); b = _bob(pose)
    # The kettle.
    c.poly([(4, 14 + b), (40, 14 + b), (34, 32 + b), (10, 32 + b)], P["percussion"])
    c.ellipse(22, 14 + b, 18, 4.5, P["paper"])
    for x in (8, 15, 22, 29, 36):
        c.line(x, 17 + b, x - (x - 22) // 5, 31 + b, P["percussion_dark"])
    _big_eyes(c, 15, 11 + b, pose, gap=10)
    c.line(19, 16 + b, 25, 16 + b, P["outline"])
    c.line(12, 32 + b, 9, 39, P["metal"], width=2); c.line(32, 32 + b, 35, 39, P["metal"], width=2)
    c.rim(P["percussion"], P["percussion_light"])
    c.outline(P["outline"])
    return c, (22, 22), (W, H)


def flute(pose):
    W, H = 80, 24
    c = Canvas(W, H); b = _bob(pose)
    c.rect(4, 9 + b, 72, 6, P["metal"])
    c.rect(4, 9 + b, 72, 1, P["metal_light"])
    c.rect(4, 8 + b, 4, 8, P["ink"])
    for x in range(20, 60, 7):
        c.circle(x, 12 + b, 1.2, P["outline"])
    # One big eye at the embouchure.
    c.circle(68, 12 + b, 5, P["eye"])
    pupil = P["hush_glow"] if pose == "windup" else P["hush_eye"]
    if pose == "hurt":
        c.line(65, 10 + b, 70, 14 + b, P["outline"]); c.line(70, 10 + b, 65, 14 + b, P["outline"])
    else:
        c.circle(69, 12 + b, 2.5, pupil); c.set(67, 10 + b, P["sparkle"])
    c.line(62, 5 + b, 72, 3 + b, P["brow"], width=2)
    c.outline(P["outline"])
    return c, (40, 12), (W, H)


def harp(pose):
    W, H = 40, 44
    c = Canvas(W, H); b = _bob(pose)
    c.rect(2, 4 + b, 9, 36, P["podium"])
    for i in range(12):
        k = i / 11
        c.line(4 + int(k * 32), 4 + b - int(math.sin(k * math.pi) * 3) + int(k * 4), 5 + int(k * 32), 5 + b - int(math.sin(k * math.pi) * 3) + int(k * 4), P["podium"], width=2)
    c.line(6, 39 + b, 36, 10 + b, P["podium"], width=3)
    for i in range(7):
        x = 11 + i * 4
        top = 4 + b + int(x / 36 * 4) - 2
        bottom = 39 + b - int((x - 6) / 30 * 29)
        c.line(x, top, x, bottom, P["string_light"])
    # A face carved into the pillar, eyes stacked because the pillar is narrow.
    pupil = P["hush_glow"] if pose == "windup" else P["hush_eye"]
    for ey in (12, 18):
        if pose == "hurt":
            c.line(4, ey + b, 7, ey + 3 + b, P["outline"]); c.line(7, ey + b, 4, ey + 3 + b, P["outline"])
        else:
            c.rect(4, ey + b, 4, 4, P["eye"]); c.rect(5, ey + 1 + b, 2, 2, pupil); c.set(4, ey + b, P["sparkle"])
    c.line(4, 25 + b, 7, 25 + b, P["outline"])
    c.rim(P["podium"], P["gold_light"])
    c.outline(P["outline"])
    return c, (20, 24), (W, H)


def conductor(pose):
    W, H = 30, 44
    c = Canvas(W, H); b = _bob(pose)
    c.poly([(8, 18 + b), (22, 18 + b), (25, 38 + b), (15, 34 + b), (5, 38 + b)], P["ink"])
    c.line(15, 18 + b, 15, 33 + b, P["paper"])
    c.ellipse(15, 11 + b, 7.5, 5.8, P["ink"])
    c.ellipse(15, 11 + b, 3.4, 3.8, P["paper"], rot=0.9)
    c.set(13, 11 + b, P["ink"]); c.set(17, 11 + b, P["ink"])
    c.set(17, 12 + b, P["gold"]) if pose != "hurt" else None
    swing = {"idle_a": 0, "idle_b": 3, "windup": -5, "hurt": 2}[pose]
    c.line(22, 22 + b, 26, 19 + b, P["ink"], width=2)
    c.line(26, 19 + b, 29, 12 + b + swing, P["paper_dark"])
    c.set(29, 11 + b + swing, P["gold_light"])
    c.line(10, 38 + b, 10, 43, P["ink"], width=2); c.line(19, 38 + b, 19, 43, P["ink"], width=2)
    c.rim(P["ink"], P["ink_light"])
    c.outline(P["outline"])
    return c, (15, 24), (W, H)


def grand_staff(pose):
    W, H = 40, 44
    c = Canvas(W, H); b = _bob(pose)
    pts = []
    for i in range(46):
        t = i / 45
        a = t * math.tau * 1.2 + math.pi * 0.5
        r = 3 + 11 * t
        pts.append((20 + math.cos(a) * r, 26 + b + math.sin(a) * r * 1.05))
    pts += [(24, 6 + b), (20, 2 + b), (16, 6 + b), (22, 30 + b), (21, 40 + b), (16, 42 + b)]
    for p0, p1 in zip(pts, pts[1:]):
        c.line(p0[0], p0[1], p1[0], p1[1], P["string_dark"], width=2)
    c.ellipse(20, 26 + b, 6, 4, P["eye"])
    pupil = P["hush_glow"] if pose == "windup" else P["gold"]
    if pose == "hurt":
        c.line(17, 24 + b, 23, 28 + b, P["outline"])
    else:
        c.circle(21, 26 + b, 2.2, pupil); c.set(19, 24 + b, P["sparkle"])
    c.outline(P["outline"])
    return c, (20, 24), (W, H)


BOSSES = {"timpani": timpani, "flute": flute, "harp": harp, "conductor": conductor, "grand_staff": grand_staff}


def sheets():
    out = {}
    for name, fn in BOSSES.items():
        frames = []
        origin = size = None
        for f in FRAMES:
            c, origin, size = fn(f)
            frames.append(c)
        out["boss_" + name] = (frames, ANIMATIONS, origin, size)
    return out
