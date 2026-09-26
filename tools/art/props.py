"""Interactable props: chest, bench, shop pedestal, sign, statue plinth, drum pad,
and the exit door (a double bar that opens)."""
from pixel import Canvas
from palette import P


def chest():
    frames = []
    for opened in (False, True):
        c = Canvas(22, 18)
        c.rect(2, 8, 18, 9, P["wood"])
        c.rect(2, 11, 18, 1, P["wood_dark"])
        if opened:
            c.poly([(2, 8), (20, 8), (18, 1), (4, 1)], P["wood_dark"])
            c.rect(6, 5, 10, 3, P["gold_light"])
        else:
            c.poly([(2, 8), (20, 8), (18, 3), (4, 3)], P["wood_light"])
            c.rect(10, 7, 3, 4, P["gold"])
        c.rim(P["wood"], P["wood_light"])
        c.outline(P["outline"])
        frames.append(c)
    return frames, {"closed": ([0], 1.0), "open": ([1], 1.0)}, (11, 17), (22, 18)


def bench():
    c = Canvas(30, 22)
    c.rect(2, 13, 26, 3, P["wood"]); c.rect(4, 16, 2, 5, P["wood_dark"]); c.rect(24, 16, 2, 5, P["wood_dark"])
    import math
    for i in range(17):
        a = math.pi + i / 16 * math.pi
        c.set(15 + round(math.cos(a) * 7), 9 + round(math.sin(a) * 6), P["ink"])
    c.circle(15, 8, 1.4, P["ink"])
    c.rim(P["wood"], P["wood_light"]); c.outline(P["outline"])
    return [c], {"idle": ([0], 1.0)}, (15, 21), (30, 22)


def pedestal():
    c = Canvas(18, 16)
    c.rect(2, 12, 14, 4, P["stone"]); c.rect(5, 4, 8, 8, P["stone_light"]); c.rect(3, 2, 12, 3, P["stone"])
    c.rim(P["stone"], P["stone_light"]); c.outline(P["outline"])
    return [c], {"idle": ([0], 1.0)}, (9, 15), (18, 16)


def sign():
    c = Canvas(22, 22)
    c.rect(10, 11, 2, 11, P["wood_dark"])
    c.rect(2, 2, 18, 10, P["wood_light"])
    for y in (4, 6, 8):
        c.line(5, y, 16 - (y - 4), y, P["wood_dark"])
    c.rim(P["wood_light"], P["paper_dark"]); c.outline(P["outline"])
    return [c], {"idle": ([0], 1.0)}, (11, 21), (22, 22)


def plinth():
    c = Canvas(26, 8)
    c.rect(1, 2, 24, 6, P["stone"]); c.rect(1, 2, 24, 1, P["stone_light"])
    c.outline(P["outline"])
    return [c], {"idle": ([0], 1.0)}, (13, 7), (26, 8)


def drum_pad():
    frames = []
    for squash in (0, 2):
        c = Canvas(28, 14)
        c.rect(2, 4 + squash, 24, 9 - squash, P["percussion"])
        c.ellipse(14, 4 + squash, 12, 2.4, P["paper"])
        for x in range(5, 25, 5):
            c.line(x, 6 + squash, x + 2, 12, P["percussion_dark"])
        c.rim(P["percussion"], P["percussion_light"]); c.outline(P["outline"])
        frames.append(c)
    return frames, {"idle": ([0], 1.0), "bounce": ([1, 0], 12.0)}, (14, 13), (28, 14)


def exit_door():
    frames = []
    for opened in (False, True):
        c = Canvas(18, 50)
        c.rect(3, 1, 2, 49, P["ink"])
        c.rect(8, 1, 5, 49, P["ink"])
        if opened:
            c.rect(14, 4, 3, 44, P["gold_light"])
            for y in range(6, 46, 6):
                c.set(15, y, P["eye"])
        else:
            for y in range(4, 48, 8):
                c.line(2, y, 15, y + 5, P["hush_light"])
        c.outline(P["outline"])
        frames.append(c)
    return frames, {"closed": ([0], 1.0), "open": ([1], 1.0)}, (9, 49), (18, 50)


PROPS = {"chest": chest, "bench": bench, "pedestal": pedestal, "sign": sign, "plinth": plinth,
         "drum_pad": drum_pad, "exit_door": exit_door}


def sheets():
    out = {}
    for name, fn in PROPS.items():
        frames, anims, origin, size = fn()
        out["prop_" + name] = (frames, anims, origin, size)
    return out
