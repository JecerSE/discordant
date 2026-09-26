"""The four playable notes. Every frame is built from the same parts (head, stem,
feet, face, accent) with a pose, so all four read as one family."""
from pixel import Canvas, eyes, blush
from palette import P

W, H = 22, 28
# Head centre inside the frame; this pixel sits on the Player node's position.
ORIGIN = (9, 18)

ACCENT = {"quarter": P["gold"], "half": P["wind"], "whole": P["percussion"], "eighth": P["string"]}

# name -> pose. bob: vertical shift; squash: 1 flatter, -1 taller; tilt: stem top
# x offset; feet: phase 0-3, "tuck" or "dangle"; face: normal, blink, hurt, focus.
POSES = {
    "idle_a": dict(bob=0, squash=0, tilt=0, feet=0, face="normal"),
    "idle_b": dict(bob=-1, squash=0, tilt=0, feet=0, face="normal"),
    "blink": dict(bob=0, squash=0, tilt=0, feet=0, face="blink"),
    "run_0": dict(bob=0, squash=0, tilt=-1, feet=1, face="focus"),
    "run_1": dict(bob=-1, squash=0, tilt=-1, feet=2, face="focus"),
    "run_2": dict(bob=0, squash=0, tilt=-1, feet=3, face="focus"),
    "run_3": dict(bob=-1, squash=0, tilt=-1, feet=0, face="focus"),
    "jump": dict(bob=-1, squash=-1, tilt=-1, feet="tuck", face="focus"),
    "fall": dict(bob=0, squash=0, tilt=1, feet="dangle", face="normal"),
    "attack_0": dict(bob=0, squash=1, tilt=4, feet=0, face="focus"),
    "attack_1": dict(bob=0, squash=0, tilt=7, feet=1, face="focus"),
    "hurt": dict(bob=1, squash=1, tilt=-2, feet="dangle", face="hurt"),
    "dash": dict(bob=0, squash=1, tilt=-3, feet="tuck", face="focus", streaks=True),
}
FRAMES = ["idle_a", "idle_b", "blink", "run_0", "run_1", "run_2", "run_3", "jump", "fall", "attack_0", "attack_1", "hurt", "dash"]
ANIMATIONS = {
    "idle": ([0, 1, 0, 2], 3.0), "run": ([3, 4, 5, 6], 10.0), "jump": ([7], 1.0), "fall": ([8], 1.0),
    "attack": ([9, 10], 14.0), "hurt": ([11], 1.0), "dash": ([12], 1.0),
}


def _feet(c, kind, cx, y, pose, accent):
    """Two little feet under the head."""
    phase = pose["feet"]
    size = 3 if kind == "whole" else 2
    left, right = cx - (4 if kind == "whole" else 3), cx + (2 if kind == "whole" else 1)
    if phase == "tuck":
        c.rect(left + 1, y - 1, size, 1, P["ink"])
        c.rect(right - 1, y - 1, size, 1, P["ink"])
        return
    if phase == "dangle":
        c.rect(left, y + 1, size, 1, P["ink"])
        c.rect(right, y + 1, size, 1, P["ink"])
        return
    lift = {0: (0, 0), 1: (-1, 0), 2: (0, -1), 3: (0, 0)}[phase]
    step = {0: (0, 0), 1: (-1, 1), 2: (0, 0), 3: (1, -1)}[phase]
    c.rect(left + step[0], y + lift[0], size, 1, P["ink"])
    c.rect(right + step[1], y + lift[1], size, 1, P["ink"])


def _face(c, kind, hx, hy, pose):
    face = pose["face"]
    light_face = kind in ("half", "whole")
    pal = dict(P)
    if light_face:
        # Dark eyes on the light hollow of the head.
        ex, ey = hx - 2, hy - 1
        if face == "blink":
            c.line(ex, ey + 1, ex + 1, ey + 1, P["ink"])
            c.line(ex + 3, ey + 1, ex + 4, ey + 1, P["ink"])
        elif face == "hurt":
            for dx in (0, 3):
                c.set(ex + dx, ey, P["ink"]); c.set(ex + dx + 1, ey + 1, P["ink"])
                c.set(ex + dx + 1, ey, P["ink"]); c.set(ex + dx, ey + 1, P["ink"])
        else:
            for dx in (0, 3):
                c.rect(ex + dx, ey, 1, 2, P["ink"])
                c.set(ex + dx + 1, ey, P["ink_light"] if face != "focus" else P["ink"])
        c.set(hx - 3, hy + 1, P["blush"])
        c.set(hx + 3, hy + 1, P["blush"])
        if kind == "whole":
            c.set(hx - 3, hy - 3, P["ink"]); c.set(hx - 2, hy - 3, P["ink"])
            c.set(hx + 2, hy - 3, P["ink"]); c.set(hx + 3, hy - 3, P["ink"])
        return
    ex, ey = hx - 3, hy - 2
    if face == "blink":
        eyes(c, ex, ey, pal, gap=4, tall=3, sleepy=True)
    elif face == "hurt":
        for dx in (0, 4):
            c.set(ex + dx, ey, P["eye"]); c.set(ex + dx + 1, ey + 1, P["eye"])
            c.set(ex + dx + 1, ey, P["eye"]); c.set(ex + dx, ey + 1, P["eye"])
            c.set(ex + dx, ey + 2, P["eye"]); c.set(ex + dx + 1, ey + 2, P["eye"])
            c.set(ex + dx, ey + 1, P["ink"])
    else:
        eyes(c, ex, ey, pal, gap=4, tall=3, look=1)
    blush(c, hx - 5, hy + 1, P)
    blush(c, hx + 3, hy + 1, P)
    if face in ("normal", "blink"):
        c.set(hx - 1, hy + 2, P["mouth"])
        c.set(hx, hy + 3, P["mouth"])
        c.set(hx + 1, hy + 2, P["mouth"])
    elif face == "focus":
        c.line(hx - 1, hy + 2, hx + 1, hy + 2, P["mouth"])


def note(kind, pose_name):
    pose = POSES[pose_name]
    c = Canvas(W, H)
    hx, hy = ORIGIN[0], ORIGIN[1] + pose["bob"]
    sq = pose["squash"]
    accent = ACCENT[kind]
    if pose.get("streaks"):
        for i, yy in enumerate((hy - 2, hy, hy + 2)):
            c.line(0, yy, 3 - i, yy, P["ink_light"])
    if kind == "whole":
        rx, ry = 8.2 + sq * 0.8, 5.8 - sq * 0.8
        c.ellipse(hx, hy + sq * 0.5, rx, ry, P["ink"])
        c.ellipse(hx, hy + sq * 0.5, 4.2, 3.4 - sq * 0.4, P["paper"], rot=0.0)
        # Headband.
        c.line(hx - 6, hy - 4 + sq, hx + 6, hy - 4 + sq, accent)
        c.set(hx + 7, hy - 5 + sq, accent)
        _feet(c, kind, hx, hy + 6, pose, accent)
    else:
        rx, ry = 6.0 + sq * 0.7, 4.4 - sq * 0.7
        c.ellipse(hx, hy + sq * 0.5, rx, ry, P["ink"], rot=-0.32)
        if kind == "half":
            c.ellipse(hx, hy + sq * 0.5, 3.8, 2.4, P["paper"], rot=0.4)
        # Stem on the right of the head, 2 px wide, swinging with the tilt.
        sx = hx + 5
        top = (sx + pose["tilt"], 2 + pose["bob"])
        c.line(sx, hy - 1, top[0], top[1], P["ink"], width=2)
        # A ribbon of the character's colour tied round the stem.
        ry_ = hy - 7
        rx_ = sx + int(round(pose["tilt"] * (hy - 1 - ry_) / max(1, hy - 1 - top[1])))
        c.set(rx_ - 1, ry_, accent); c.set(rx_ + 2, ry_, accent); c.set(rx_ - 1, ry_ + 1, accent)
        if kind == "eighth":
            fx, fy = top
            flap = 1 if pose_name in ("idle_b", "run_1", "run_3", "fall") else 0
            pts = [(fx + 1, fy), (fx + 3, fy + 2 + flap), (fx + 4, fy + 4 + flap), (fx + 4, fy + 6), (fx + 3, fy + 8)]
            for a, b in zip(pts, pts[1:]):
                c.line(a[0], a[1], b[0], b[1], P["ink"], width=2)
            c.set(fx + 4, fy + 7, accent)
        _feet(c, kind, hx, hy + 5, pose, accent)
    _face(c, kind, hx, hy, pose)
    c.rim(P["ink"], P["ink_light"])
    c.outline(P["outline"])
    return c


def sheets():
    """name -> (frames, animations, origin, frame size)."""
    out = {}
    for kind in ("quarter", "half", "whole", "eighth"):
        out["note_" + kind] = ([note(kind, f) for f in FRAMES], ANIMATIONS, ORIGIN, (W, H))
    return out
