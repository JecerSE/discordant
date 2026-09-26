"""Teachers and townsfolk of the Margin. Two idle frames each."""
from pixel import Canvas, eyes, blush
from palette import P

W, H = 26, 32
ORIGIN = (13, 31)   # feet: NPCs stand on the floor
ANIMATIONS = {"idle": ([0, 1], 2.0)}


def _friendly_eyes(c, x, y, sleepy=False, gap=4):
    eyes(c, x, y, dict(P), gap=gap, tall=3, sleepy=sleepy)


def old_snare(f):
    c = Canvas(W, H); b = -f
    c.rect(5, 16 + b, 16, 14, P["percussion"])
    c.ellipse(13, 16 + b, 8, 2.2, P["paper"])
    for x in (7, 11, 15, 19):
        c.line(x, 18 + b, x + 1, 29 + b, P["metal_light"])
    _friendly_eyes(c, 8, 20 + b)
    c.line(9, 25 + b, 17, 25 + b, P["paper"])          # the moustache
    c.set(8, 26 + b, P["paper"]); c.set(18, 26 + b, P["paper"])
    c.line(3, 18 + b, 1, 6 + b + f, P["wood_light"], width=2)
    c.circle(1, 5 + b + f, 1.6, P["percussion_light"])
    c.rim(P["percussion"], P["percussion_light"]); c.outline(P["outline"])
    return c


def zephyrine(f):
    c = Canvas(W, H); b = -f
    c.poly([(7, 14 + b), (19, 14 + b), (22, 30), (4, 30)], P["wind"])
    c.circle(13, 10 + b, 5.5, P["paper"])
    c.rect(8, 4 + b, 10, 3, P["wind_dark"])
    _friendly_eyes(c, 10, 9 + b, sleepy=(f == 1), gap=3)
    blush(c, 9, 12 + b, P); blush(c, 16, 12 + b, P)
    c.line(20, 20 + b, 25, 6 + b, P["metal"], width=2)
    c.rim(P["wind"], P["wind_light"]); c.outline(P["outline"])
    return c


def luthier(f):
    c = Canvas(W, H); b = -f
    c.rect(7, 15 + b, 12, 15, P["wood_dark"])
    c.circle(13, 10 + b, 5.5, P["paper"])
    c.rect(8, 4 + b, 10, 2, P["ink"])
    _friendly_eyes(c, 10, 9 + b, gap=3)
    c.rect(9, 9 + b, 3, 1, P["gold"]); c.rect(14, 9 + b, 3, 1, P["gold"])   # glasses
    c.ellipse(21, 22 + b, 3, 4.5, P["wood"])
    c.line(21, 17 + b, 21, 12 + b, P["wood_dark"])
    c.rim(P["wood_dark"], P["wood"]); c.outline(P["outline"])
    return c


def bflat(f):
    c = Canvas(W, H); b = -f
    c.line(9, 6 + b, 9, 30, P["ink"], width=3)
    c.ellipse(14, 23 + b, 6, 5.5, P["ink"])
    c.ellipse(14, 23 + b, 3, 3.2, P["paper"])
    c.rect(4, 5 + b, 12, 2, P["ink"]); c.rect(6, -1 + b, 8, 6, P["ink"]); c.rect(6, 3 + b, 8, 1, P["gold"])
    _friendly_eyes(c, 11, 11 + b, gap=4)
    c.circle(16, 12 + b, 2.2, P["gold"])   # monocle
    c.circle(16, 12 + b, 1.2, P["eye"])
    c.rim(P["ink"], P["ink_light"]); c.outline(P["outline"])
    return c


def pause(f):
    c = Canvas(W, H); b = -f
    c.rect(1, 29, 24, 1, P["ink"])
    c.rect(5, 19 + b, 16, 10 - b, P["ink"])
    _friendly_eyes(c, 8, 22 + b, sleepy=(f == 1), gap=6)
    blush(c, 7, 26 + b, P); blush(c, 17, 26 + b, P)
    c.set(12, 26 + b, P["mouth"]); c.set(13, 27 + b, P["mouth"]); c.set(14, 26 + b, P["mouth"])
    c.rim(P["ink"], P["ink_light"]); c.outline(P["outline"])
    return c


def scribble(f):
    c = Canvas(W, H); b = -f
    import math
    for i in range(40):
        t = i / 39
        x = 5 + t * 16
        y = 22 + b + math.sin(t * 14 + f) * 3
        c.set(x, y, P["margin"]); c.set(x, y + 1, P["margin"])
    c.line(18, 12 + b, 22, 28, P["margin"], width=2)
    c.line(21, 26, 23, 30, P["paper_shade"], width=2)
    _friendly_eyes(c, 9, 17 + b, gap=4)
    c.outline(P["outline"])
    return c


NPCS = {"old_snare": old_snare, "zephyrine": zephyrine, "luthier": luthier, "bflat": bflat, "pause": pause, "scribble": scribble}


def sheets():
    return {"npc_" + k: ([fn(0), fn(1)], ANIMATIONS, ORIGIN, (W, H)) for k, fn in NPCS.items()}
