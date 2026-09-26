"""The fallen champions: bigger Rests wearing a gold crown and carrying the
instrument they drop when beaten."""
from pixel import Canvas, eyes
from palette import P

W, H = 28, 28
ORIGIN = (14, 15)
FRAMES = ["idle_a", "idle_b", "windup", "attack"]
ANIMATIONS = {"idle": ([0, 1], 3.0), "windup": ([2], 1.0), "attack": ([3], 1.0)}


def _pose(name):
    return {"idle_a": (0, 0), "idle_b": (-1, 0), "windup": (1, 1), "attack": (0, -1)}[name]


def _body(c, cx, cy, rx, ry, pose):
    bob, sq = _pose(pose)
    c.ellipse(cx, cy + bob + sq * 0.5, rx + sq * 0.6, ry - sq * 0.6, P["hush"])
    pupil = P["hush_glow"] if pose == "windup" else P["hush_eye"]
    eyes(c, cx - 4, cy + bob - 2, dict(P), gap=5, tall=3, pupil=pupil, angry=True)
    c.line(cx - 1, cy + bob + 3, cx + 1, cy + bob + 3, P["hush_dark"])
    return bob


def _crown(c, cx, top):
    c.rect(cx - 4, top, 9, 2, P["gold"])
    for x in (cx - 4, cx, cx + 4):
        c.set(x, top - 1, P["gold"]); c.set(x, top - 2, P["gold_light"])


def _finish(c):
    c.rim(P["hush"], P["hush_light"])
    c.rim(P["gold"], P["gold_light"])
    c.outline(P["outline"])
    return c


def timpanist(pose):
    c = Canvas(W, H)
    bob = _body(c, 12, 15, 7.5, 6.5, pose)
    _crown(c, 12, 6 + bob)
    swing = -3 if pose in ("windup", "idle_b") else 0
    for sx in (20, 23):
        c.line(sx, 16 + bob, sx + 2, 9 + bob + swing, P["wood_light"])
        c.circle(sx + 2, 8 + bob + swing, 1.5, P["percussion_light"])
    return _finish(c)


def cymbalist(pose):
    c = Canvas(W, H)
    bob = _body(c, 14, 15, 7, 6.5, pose)
    _crown(c, 14, 6 + bob)
    gap = 0 if pose == "attack" else 3
    for sx in (3 - gap // 2, 25 + gap // 2):
        c.ellipse(sx, 15 + bob, 2, 6, P["gold"])
        c.set(sx, 15 + bob, P["gold_light"])
    return _finish(c)


def piper(pose):
    c = Canvas(W, H)
    bob = _body(c, 12, 12, 6.5, 6, pose)
    _crown(c, 12, 4 + bob)
    c.line(15, 17 + bob, 26, 13 + bob, P["metal"], width=2)
    for x in (19, 22):
        c.set(x, 15 + bob, P["outline"])
    c.line(12, 18 + bob, 15, 24 + bob, P["hush"], width=2)
    return _finish(c)


def hornist(pose):
    c = Canvas(W, H)
    bob = _body(c, 11, 15, 7, 6.5, pose)
    _crown(c, 11, 6 + bob)
    flare = 1 if pose in ("windup", "attack") else 0
    c.line(17, 16 + bob, 22, 16 + bob, P["gold"], width=2)
    c.poly([(22, 13 + bob - flare), (27, 10 + bob - flare), (27, 22 + bob + flare), (22, 19 + bob + flare)], P["gold"])
    return _finish(c)


def violist(pose):
    c = Canvas(W, H)
    bob = _body(c, 11, 13, 6.5, 6, pose)
    _crown(c, 11, 4 + bob)
    c.ellipse(20, 17 + bob, 3, 4.5, P["wood"])
    c.line(20, 12 + bob, 20, 6 + bob, P["wood_dark"])
    bow = -2 if pose in ("idle_b", "attack") else 1
    c.line(15, 22 + bob + bow, 26, 13 + bob + bow, P["paper_dark"])
    return _finish(c)


def cellist(pose):
    c = Canvas(W, H)
    bob = _body(c, 10, 14, 6.5, 7, pose)
    _crown(c, 10, 4 + bob)
    c.ellipse(20, 18 + bob, 4.5, 7, P["wood"])
    c.line(20, 10 + bob, 20, 3 + bob, P["wood_dark"])
    c.line(20, 25 + bob, 20, 27, P["metal"])
    for y in (15, 21):
        c.set(18, y + bob, P["wood_dark"]); c.set(22, y + bob, P["wood_dark"])
    return _finish(c)


SPECIES = {"timpanist": timpanist, "cymbalist": cymbalist, "piper": piper,
           "hornist": hornist, "violist": violist, "cellist": cellist}


def sheets():
    return {"enemy_" + k: ([fn(f) for f in FRAMES], ANIMATIONS, ORIGIN, (W, H)) for k, fn in SPECIES.items()}
