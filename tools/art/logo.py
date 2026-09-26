"""The title logo: "THE DISCORDANT" in a chunky hand-made pixel font. The O is a whole
note, and a few letters sit a pixel off the line, slightly out of tune. Writes
assets/ui/logo.png (drawn at 6x in game)."""
import os
from pixel import Canvas, hexc
from palette import P

BIG = {
    "D": ["######.", "##...##", "##...##", "##...##", "##...##", "##...##", "##...##", "##...##", "######."],
    "I": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "######"],
    "S": [".#####.", "##...##", "##.....", "##.....", ".#####.", ".....##", ".....##", "##...##", ".#####."],
    "C": [".#####.", "##...##", "##.....", "##.....", "##.....", "##.....", "##.....", "##...##", ".#####."],
    # A whole note: thick sides, a tilted hole.
    "O": ["..#####..", ".##..####", "##....###", "##.....##", "##.....##", "##.....##", "###....##", "####..##.", "..#####.."],
    "R": ["######.", "##...##", "##...##", "##...##", "######.", "##.##..", "##..##.", "##...##", "##...##"],
    "A": ["..###..", ".##.##.", "##...##", "##...##", "#######", "##...##", "##...##", "##...##", "##...##"],
    "N": ["##...##", "###..##", "####.##", "##.####", "##..###", "##...##", "##...##", "##...##", "##...##"],
    "T": ["########", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##...", "...##..."],
}
SMALL = {
    "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "E": ["###", "#..", "##.", "#..", "###"],
}
# Vertical nudge per letter of DISCORDANT: the discord.
NUDGE = [0, 0, 1, 0, -1, 0, 0, 1, 0, 0]
PAD = 4


def _glyph(c, rows, ox, oy, col):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                c.set(ox + x, oy + y, col)


def _width(word, font, gap):
    return sum(len(font[ch][0]) for ch in word) + gap * (len(word) - 1)


def logo():
    word = "DISCORDANT"
    w = _width(word, BIG, 1) + PAD * 2
    h = 5 + 2 + 9 + 2 + 3 + PAD * 2
    cream, cream_dark, white = hexc("f3ecd9"), hexc("d9ceb2"), hexc("fffaf0")
    gold = P["gold"]
    letters = Canvas(w, h)
    x = PAD
    base = PAD + 7
    for i, ch in enumerate(word):
        _glyph(letters, BIG[ch], x, base + NUDGE[i], cream)
        x += len(BIG[ch][0]) + 1
    # Shade the underside of every stroke, light its top-left edge.
    for yy in range(h - 1, -1, -1):
        for xx in range(w):
            if letters.get(xx, yy) == cream and letters.get(xx, yy + 1)[3] == 0:
                letters.set(xx, yy, cream_dark)
    letters.rim(cream, white)
    x = PAD
    for ch in "THE":
        _glyph(letters, SMALL[ch], x, PAD, gold)
        x += 4
    letters.outline(P["outline"])
    # A solid extruded shadow: gold for two pixels under the outline, then a dark edge.
    out = Canvas(w, h)
    for yy in range(h):
        for xx in range(w):
            if letters.get(xx, yy)[3] > 0:
                out.set(xx, yy + 1, hexc("bf993b"))
                out.set(xx, yy + 2, hexc("8a6a24"))
                out.set(xx, yy + 3, P["outline"])
    out.paste(letters, 0, 0)
    return out


def build(root, preview_dir=None):
    os.makedirs(os.path.join(root, "assets", "ui"), exist_ok=True)
    img = logo().image()
    img.save(os.path.join(root, "assets", "ui", "logo.png"))
    if preview_dir:
        from PIL import Image
        big = img.resize((img.width * 6, img.height * 6), Image.NEAREST)
        bg = Image.new("RGBA", big.size, (20, 22, 48, 255))
        bg.alpha_composite(big)
        bg.save(os.path.join(preview_dir, "logo.png"))
    return 1
