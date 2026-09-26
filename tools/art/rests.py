"""The Rests: small, round, angry and a little cute. Each species keeps its rest
symbol in the silhouette (the quarter-rest zigzag, the eighth-rest flag, the
whole-rest block) so players can read them at a glance."""
import math
from pixel import Canvas, eyes
from palette import P

W, H = 20, 20
ORIGIN = (10, 11)
FRAMES = ["idle_a", "idle_b", "windup", "attack"]
ANIMATIONS = {"idle": ([0, 1], 3.0), "windup": ([2], 1.0), "attack": ([3], 1.0)}


def _pose(name):
    return {"idle_a": (0, 0), "idle_b": (-1, 0), "windup": (1, 1), "attack": (0, -1)}[name]


def _face(c, x, y, pose, gap=3, tall=2):
    """Angry cute face. Eyes glow gold while winding up."""
    pal = dict(P)
    pupil = P["hush_glow"] if pose == "windup" else P["hush_eye"]
    eyes(c, x, y, pal, gap=gap, tall=tall, pupil=pupil, angry=True)
    c.set(x + gap // 2 + 1, y + tall + 1, P["hush_eye"] if pose != "windup" else P["hush_glow"])


def _finish(c, body=None):
    c.rim(body or P["hush"], P["hush_light"])
    c.outline(P["outline"])
    return c


def _blob(c, cx, cy, rx, ry, squash):
    c.ellipse(cx, cy + squash * 0.5, rx + squash * 0.6, ry - squash * 0.6, P["hush"])


# ------------------------------------------------------------------- species
def quarter_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 12 + bob
    _blob(c, 10, cy, 5.5, 4.8, sq)
    # The zigzag tuft of a quarter rest.
    for a, b in [((9, cy - 4), (12, cy - 7)), ((12, cy - 7), (9, cy - 9)), ((9, cy - 9), (11, cy - 11))]:
        c.line(a[0], a[1], b[0], b[1], P["hush"], width=2)
    _face(c, 7, cy - 1, pose)
    c.rect(7, cy + 5, 2, 1, P["hush_dark"]); c.rect(11, cy + 5, 2, 1, P["hush_dark"])
    return _finish(c)


def eighth_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 9 + bob
    c.circle(9, cy, 4.6, P["hush"])
    # Flag tail curling down: the stroke of an eighth rest.
    for a, b in [((12, cy + 2), (14, cy + 5)), ((14, cy + 5), (12, cy + 9))]:
        c.line(a[0], a[1], b[0], b[1], P["hush"], width=2)
    # Little wings that flap.
    up = -1 if pose in ("idle_b", "attack") else 1
    c.line(4, cy, 1, cy - 2 * up, P["hush_light"], width=1)
    c.line(4, cy + 1, 2, cy - 1 * up, P["hush_light"], width=1)
    _face(c, 6, cy - 1, pose)
    return _finish(c)


def sixteenth_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 7 + bob
    c.circle(9, cy, 3.8, P["hush"])
    c.circle(8, cy + 7, 3.0, P["hush"])
    c.line(12, cy + 1, 13, cy + 9, P["hush"], width=2)
    _face(c, 6, cy - 1, pose)
    c.set(8, cy + 7, P["hush_eye"])
    return _finish(c)


def whole_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    # A heavy block hanging from its staff line.
    c.rect(1, 4, 18, 1, P["ink"])
    c.rect(4, 5 + bob, 12, 8 - sq, P["hush"])
    c.rect(4, 5 + bob, 12, 1, P["hush_dark"])
    _face(c, 6, 8 + bob, pose, gap=5)
    c.line(8, 12 + bob, 11, 12 + bob, P["hush_dark"])
    return _finish(c)


def half_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    c.rect(4, 7 + bob + sq, 12, 8 - sq, P["hush"])
    c.rect(1, 15, 18, 1, P["ink"])
    _face(c, 6, 9 + bob + sq, pose, gap=5)
    # Little horns.
    c.set(5, 6 + bob + sq, P["hush"]); c.set(14, 6 + bob + sq, P["hush"])
    return _finish(c)


def snare_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    top = 8 + bob + sq
    c.rect(4, top, 12, 8 - sq, P["percussion_dark"])
    c.ellipse(10, top, 6, 1.6, P["paper"])
    for i in range(4):
        c.line(5 + i * 3, top + 2, 6 + i * 3, top + 7 - sq, P["metal_light"])
    for a, b in [((9, top - 2), (12, top - 5)), ((12, top - 5), (10, top - 7))]:
        c.line(a[0], a[1], b[0], b[1], P["hush"], width=2)
    _face(c, 6, top + 3, pose, gap=5)
    return _finish(c, P["percussion_dark"])


def gust_rest(pose):
    c = eighth_rest(pose)
    t = 1 if pose in ("idle_b", "attack") else 0
    for i, yy in enumerate((5, 9, 13)):
        c.line(15 - t + i % 2, yy, 18 - t, yy, P["wind_light"])
    return c


def tether_rest(pose):
    c = quarter_rest(pose)
    bob, _ = _pose(pose)
    for a in range(0, 360, 45):
        r = math.radians(a)
        c.set(15 + round(math.cos(r) * 2), 3 + bob + round(math.sin(r) * 2), P["string_light"])
    c.line(13, 6 + bob, 14, 5 + bob, P["string_light"])
    return c


def echo_rest(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 10 + bob
    c.circle(10, cy, 4.2, P["hush"])
    _face(c, 7, cy - 1, pose)
    c2 = Canvas(W, H)
    rr = 7 if pose in ("idle_a", "windup") else 8
    for a in range(0, 360, 12):
        r = math.radians(a)
        if 40 < a < 140 or 220 < a < 320:
            continue
        c2.set(10 + round(math.cos(r) * rr), cy + round(math.sin(r) * rr), P["string_light"])
    _finish(c)
    c.paste(c2, 0, 0)
    return c


def rim_guard(pose):
    c = half_rest(pose)
    bob, sq = _pose(pose)
    # A drum-rim shield held in front.
    for y in range(6 + bob, 15 + bob):
        c.set(17, y, P["percussion"]); c.set(18, y, P["percussion_light"])
    c.set(17, 5 + bob, P["outline"]); c.set(18, 5 + bob, P["outline"])
    return c


def bandleader(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 12 + bob
    _blob(c, 10, cy, 5.5, 4.8, sq)
    c.rect(7, cy - 8, 6, 4, P["ink"]); c.rect(5, cy - 4, 10, 1, P["ink"]); c.rect(7, cy - 5, 6, 1, P["gold"])
    _face(c, 7, cy - 1, pose)
    wave = -2 if pose in ("idle_b", "windup") else 0
    c.line(15, cy, 18, cy - 4 + wave, P["paper_dark"])
    c.set(18, cy - 5 + wave, P["gold_light"])
    return _finish(c)


def dasher(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    cy = 11 + bob
    c.ellipse(11, cy, 5 + (1 if pose == "attack" else 0), 3.6, P["hush"])
    c.poly([(6, cy - 3), (2, cy), (6, cy + 3)], P["hush"])
    _face(c, 10, cy - 2, pose, gap=3)
    if pose in ("attack", "idle_b"):
        for yy in (cy - 2, cy + 2):
            c.line(0, yy, 1, yy, P["hush_light"])
    return _finish(c)


def phantom(pose):
    c = eighth_rest(pose)
    # Wispy, see-through body.
    for y in range(c.h):
        for x in range(c.w):
            p = c.px[y][x]
            if p[3] and p not in (P["eye"], P["hush_eye"], P["hush_glow"], P["sparkle"]):
                c.px[y][x] = (p[0], p[1], p[2], 150)
    for x in (6, 9, 12):
        c.set(x, 15, (108, 93, 146, 110)); c.set(x + 1, 16, (108, 93, 146, 70))
    return c


def breath_well(pose):
    c = Canvas(W, H); bob, sq = _pose(pose)
    breathe = 1 if pose in ("idle_b", "windup") else 0
    c.rect(7 - breathe, 3, 6 + breathe * 2, 16, P["wind_dark"])
    c.rect(6 - breathe, 3, 8 + breathe * 2, 2, P["wind"])
    for y in (8, 11, 14):
        c.set(10, y, P["outline"])
    eyes(c, 8, 5, dict(P), gap=3, tall=2, sleepy=(pose == "idle_a"))
    c.rim(P["wind_dark"], P["wind"])
    c.outline(P["outline"])
    return c


def motif_rest(pose):
    c = sixteenth_rest(pose)
    bob, _ = _pose(pose)
    # A tiny eighth note floating beside it: the motif it plays.
    c.rect(15, 6 + bob, 2, 2, P["margin"])
    c.line(17, 2 + bob, 17, 7 + bob, P["margin"])
    c.set(18, 3 + bob, P["margin"]); c.set(19, 4 + bob, P["margin"])
    return c


def binder_rest(pose):
    c = tether_rest(pose)
    bob, _ = _pose(pose)
    for a in range(0, 360, 45):
        r = math.radians(a)
        c.set(4 + round(math.cos(r) * 2), 3 + bob + round(math.sin(r) * 2), P["string_light"])
    return c


def warden_rest(pose):
    c = echo_rest(pose)
    bob, _ = _pose(pose)
    for y in range(3 + bob, 17 + bob):
        c.set(1, y, P["string"]); c.set(18, y, P["string"])
    return c


def dummy(pose):
    c = Canvas(W, H)
    c.rect(9, 10, 2, 9, P["wood"])
    c.rect(5, 18, 10, 2, P["wood_dark"])
    c.circle(10, 7, 6, P["paper"])
    c.circle(10, 7, 4, P["red"])
    c.circle(10, 7, 2.2, P["paper"])
    c.set(10, 7, P["red"])
    if pose == "windup":
        c.shift(1, 0)
    c.outline(P["outline"])
    return c


SPECIES = {
    "quarter_rest": quarter_rest, "eighth_rest": eighth_rest, "sixteenth_rest": sixteenth_rest,
    "whole_rest": whole_rest, "half_rest": half_rest, "snare_rest": snare_rest, "gust_rest": gust_rest,
    "tether_rest": tether_rest, "echo_rest": echo_rest, "rim_guard": rim_guard, "bandleader": bandleader,
    "dasher": dasher, "phantom": phantom, "breath_well": breath_well, "motif_rest": motif_rest,
    "binder_rest": binder_rest, "warden_rest": warden_rest, "dummy": dummy,
}


def sheets():
    return {"enemy_" + k: ([fn(f) for f in FRAMES], ANIMATIONS, ORIGIN, (W, H)) for k, fn in SPECIES.items()}
