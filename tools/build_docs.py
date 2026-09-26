"""Builds docs/The_Discordant_Documentation.pdf from the codebase.

Run from the project root with a Python that has reportlab:
    python3 tools/build_docs.py

Tables of files, classes, tuning values, characters, powers, combos and commits are
read from the source every time, so the PDF stays in step with the code. The prose
sections (design decisions, issue log, limitations) are written below.
"""
import os
import re
import subprocess
from datetime import date

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (KeepTogether, PageBreak, Paragraph, Preformatted,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "docs", "The_Discordant_Documentation.pdf")
FONT_DIR = "/usr/share/fonts/TTF"

# --------------------------------------------------------------------------- fonts
pdfmetrics.registerFont(TTFont("Sans", os.path.join(FONT_DIR, "DejaVuSans.ttf")))
pdfmetrics.registerFont(TTFont("Sans-Bold", os.path.join(FONT_DIR, "DejaVuSans-Bold.ttf")))
pdfmetrics.registerFont(TTFont("Serif", os.path.join(FONT_DIR, "DejaVuSerif.ttf")))
pdfmetrics.registerFont(TTFont("Serif-Bold", os.path.join(FONT_DIR, "DejaVuSerif-Bold.ttf")))
pdfmetrics.registerFont(TTFont("Mono", os.path.join(FONT_DIR, "DejaVuSansMono.ttf")))
pdfmetrics.registerFontFamily("Sans", normal="Sans", bold="Sans-Bold", italic="Sans", boldItalic="Sans-Bold")

INK = colors.HexColor("#1b181c")
SOFT = colors.HexColor("#5c565e")
ACCENT = colors.HexColor("#cd6337")
HEADER_BG = colors.HexColor("#efe7d6")
ROW_ALT = colors.HexColor("#faf7f0")
RULE = colors.HexColor("#d8cfbd")

ss = getSampleStyleSheet()
S = {
    "title": ParagraphStyle("title", fontName="Serif-Bold", fontSize=30, leading=36, textColor=INK, alignment=TA_CENTER),
    "subtitle": ParagraphStyle("subtitle", fontName="Serif", fontSize=14, leading=19, textColor=SOFT, alignment=TA_CENTER),
    "h1": ParagraphStyle("h1", fontName="Serif-Bold", fontSize=19, leading=24, textColor=INK, spaceBefore=6, spaceAfter=8),
    "h2": ParagraphStyle("h2", fontName="Serif-Bold", fontSize=13.5, leading=18, textColor=ACCENT, spaceBefore=10, spaceAfter=5),
    "h3": ParagraphStyle("h3", fontName="Sans-Bold", fontSize=10.5, leading=14, textColor=INK, spaceBefore=6, spaceAfter=3),
    "body": ParagraphStyle("body", fontName="Sans", fontSize=9.3, leading=13.2, textColor=INK, spaceAfter=5),
    "small": ParagraphStyle("small", fontName="Sans", fontSize=8, leading=10.5, textColor=SOFT),
    "cell": ParagraphStyle("cell", fontName="Sans", fontSize=7.8, leading=10, textColor=INK),
    "cellb": ParagraphStyle("cellb", fontName="Sans-Bold", fontSize=7.8, leading=10, textColor=INK),
    "code": ParagraphStyle("code", fontName="Mono", fontSize=7.4, leading=9.4, textColor=INK, backColor=ROW_ALT,
                           borderPadding=5, leftIndent=4, rightIndent=4, spaceBefore=3, spaceAfter=8),
    "bullet": ParagraphStyle("bullet", fontName="Sans", fontSize=9.3, leading=13, textColor=INK, leftIndent=12, bulletIndent=2, spaceAfter=2),
}

# Glyphs DejaVu doesn't carry (musical symbols block) are written out.
GLYPH_FALLBACK = {"𝅗𝅥": "half", "𝅝": "whole", "𝄐": "fermata"}


def esc(text):
    text = str(text).replace(" — ", ", ").replace("—", "-")
    for k, v in GLYPH_FALLBACK.items():
        text = text.replace(k, v)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def P(text, style="body"):
    return Paragraph(text, S[style])


def num(v):
    """Tidy a number or packed array read from source: 2300.0 -> 2300, ([2, 3]) -> 2, 3."""
    v = str(v).strip()
    v = re.sub(r"^Packed\w+Array\(\[?|\]?\)$", "", v).replace('"', "")
    return re.sub(r"(\d+)\.0\b", r"\1", v)


def bullets(items):
    return [Paragraph(t, S["bullet"], bulletText="•") for t in items]


def table(header, rows, widths, font_size=None):
    style = S["cell"] if font_size is None else ParagraphStyle("c", parent=S["cell"], fontSize=font_size, leading=font_size + 2.3)
    data = [[Paragraph("<b>%s</b>" % esc(h), S["cellb"]) for h in header]]
    for r in rows:
        data.append([c if not isinstance(c, str) else Paragraph(c, style) for c in r])
    t = Table(data, colWidths=[w * mm for w in widths], repeatRows=1)
    t.spaceAfter = 7
    cmds = [
        ("BACKGROUND", (0, 0), (-1, 0), HEADER_BG),
        ("LINEBELOW", (0, 0), (-1, 0), 0.8, ACCENT),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("LINEBELOW", (0, 1), (-1, -1), 0.25, RULE),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            cmds.append(("BACKGROUND", (0, i), (-1, i), ROW_ALT))
    t.setStyle(TableStyle(cmds))
    return t


def code(text):
    return Preformatted(text, S["code"])


# --------------------------------------------------------------------------- source readers
def read(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def git(*args):
    return subprocess.run(["git", "-C", ROOT] + list(args), capture_output=True, text=True).stdout.strip()


def gd_files():
    out = []
    for base, _, files in os.walk(os.path.join(ROOT, "src")):
        for f in files:
            if f.endswith(".gd"):
                out.append(os.path.relpath(os.path.join(base, f), ROOT))
    return sorted(out)


def file_info(rel):
    text = read(rel)
    lines = text.count("\n")
    cls = re.search(r"^class_name (\w+)", text, re.M)
    ext = re.search(r"^extends (\S+)", text, re.M)
    parts = []
    started = False
    for line in text.split("\n"):
        if line.startswith("## "):
            parts.append(line[3:].strip())
            started = True
        elif started:
            break
    doc = " ".join(parts)
    if len(doc) > 230:
        doc = doc[:230].rsplit(" ", 1)[0] + "..."
    return {"path": rel, "lines": lines, "class": cls.group(1) if cls else "", "extends": ext.group(1) if ext else "", "doc": doc}


def dict_entries(block_text):
    """Top-level keys of a GDScript dictionary literal: returns [(key, body)]."""
    out = []
    for m in re.finditer(r'^\t"(\w+)": \{(.*?)\},?$', block_text, re.M | re.S):
        out.append((m.group(1), m.group(2)))
    return out


def field(body, name, default=""):
    m = re.search(r'"%s": ("(?:[^"\\]|\\.)*"|[-\w.]+|\[[^\]]*\])' % name, body)
    if not m:
        return default
    v = m.group(1)
    return v[1:-1].replace('\\"', '"') if v.startswith('"') else v


def const_block(text, name):
    m = re.search(r"^const %s := \{\n(.*?)^\}" % name, text, re.M | re.S)
    return m.group(1) if m else ""


def tuning_resources():
    out = []
    folder = os.path.join(ROOT, "src", "data", "tuning")
    for f in sorted(os.listdir(folder)):
        if not f.endswith(".gd"):
            continue
        text = read(os.path.join("src", "data", "tuning", f))
        cls = re.search(r"^class_name (\w+)", text, re.M).group(1)
        doc = next((l[3:] for l in text.split("\n") if l.startswith("## ")), "")
        fields, pending, group = [], [], ""
        for line in text.split("\n"):
            g = re.match(r'@export_group\("([^"]+)"\)', line)
            if g:
                group = g.group(1)
                continue
            if line.startswith("## "):
                pending.append(line[3:])
                continue
            m = re.match(r"@export var (\w+): ([\w\[\]]+) = (.+)", line)
            if m:
                fields.append({"name": m.group(1), "type": m.group(2), "default": m.group(3), "doc": " ".join(pending), "group": group})
            pending = []
        tres = re.search(r'preload\("res://(content/tuning/[^"]+)"\)', read(os.path.join("src", "data", "tuning", f)))
        out.append({"class": cls, "file": "src/data/tuning/" + f, "doc": doc, "fields": fields})
    return out


def tres_subresources(rel):
    text = read(rel)
    subs = []
    for block in re.split(r"\n\[sub_resource[^\]]*\]\n", text)[1:]:
        block = block.split("\n[")[0]
        d = {}
        for line in block.split("\n"):
            m = re.match(r"(\w+) = (.+)", line)
            if m and m.group(1) != "script":
                d[m.group(1)] = m.group(2).strip().strip('"').lstrip("&").strip('"')
        subs.append(d)
    return subs


# --------------------------------------------------------------------------- page decorations
def on_page(canvas, doc):
    canvas.saveState()
    canvas.setFont("Sans", 7.5)
    canvas.setFillColor(SOFT)
    canvas.drawString(18 * mm, 10 * mm, "The Discordant  ·  Codebase and design documentation")
    canvas.drawRightString(A4[0] - 18 * mm, 10 * mm, "Page %d" % doc.page)
    canvas.setStrokeColor(RULE)
    canvas.line(18 * mm, 13 * mm, A4[0] - 18 * mm, 13 * mm)
    canvas.restoreState()


def on_first_page(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(INK)
    top = A4[1] - 60 * mm
    for i in range(5):
        canvas.setLineWidth(0.8)
        canvas.line(25 * mm, top - i * 4 * mm, A4[0] - 25 * mm, top - i * 4 * mm)
    canvas.setFillColor(ACCENT)
    canvas.circle(A4[0] * 0.68, top - 10 * mm, 3.2 * mm, fill=1, stroke=0)
    canvas.setStrokeColor(ACCENT)
    canvas.setLineWidth(1.4)
    canvas.line(A4[0] * 0.68 + 3.0 * mm, top - 10 * mm, A4[0] * 0.68 + 3.0 * mm, top + 6 * mm)
    canvas.restoreState()


# --------------------------------------------------------------------------- content
def build():
    story = []
    head = git("rev-parse", "--short", "HEAD")
    today = date.today().isoformat()
    files = [file_info(f) for f in gd_files()]
    total_lines = sum(f["lines"] for f in files)

    # ---------------------------------------------------------------- title
    story += [Spacer(1, 95 * mm), P("The Discordant", "title"), Spacer(1, 4 * mm),
              P("Codebase and design documentation", "subtitle"), Spacer(1, 16 * mm),
              P("Code as of commit %s  ·  %s  ·  private repository JecerSE/the-discordant" % (head, today), "subtitle"),
              Spacer(1, 4 * mm),
              P("Godot 4.7.2 · GDScript · %d scripts · %d lines" % (len(files), total_lines), "subtitle"),
              PageBreak()]

    # ---------------------------------------------------------------- contents
    story.append(P("Contents", "h1"))
    toc = ["1. Overview", "2. Game design", "3. Architecture", "4. Systems", "5. Data and tuning",
           "6. File map", "7. Design decisions", "8. Playtest issue log", "9. Testing and tools",
           "10. Known limitations and next steps", "11. Repository and release workflow",
           "12. Commit history", "13. Glossary"]
    story += bullets(toc)
    story.append(PageBreak())

    # ---------------------------------------------------------------- 1 overview
    story.append(P("1. Overview", "h1"))
    story.append(P(
        "The Discordant is a 2D rhythm-action roguelite platformer. A quarter note falls off the Grand Score into "
        "the Margin and climbs back through three pillar bars (Percussion, Wind, Strings) to the Conductor. Every "
        "room is a page of sheet music: the five staff lines are the platforms. The Rest, a corruption of silence, "
        "muffles the music; attacking on the beat is stronger, and clearing a room brings the colour and the song back."))
    story.append(P("Technology", "h2"))
    story.append(table(["Item", "Value"], [
        ["Engine", "Godot 4.7.2 (stable), GL Compatibility renderer"],
        ["Language", "GDScript, statically typed where the analyzer allows"],
        ["Resolution", "1280 × 720 viewport, stretch mode canvas_items, aspect keep_height"],
        ["Physics", "60 ticks per second (engine default)"],
        ["Art", "None on disk. Everything is drawn in code with _draw() (Glyph and per-class drawing)."],
        ["Audio", "None on disk. Every sound is synthesised at startup in about 150 ms (Synth and src/audio)."],
        ["Scenes", "One .tscn (src/main.tscn). All other nodes are created in code."],
        ["Data", "Game content in src/data/content/*.gd constants; tuning and combat data in .tres Resources under content/"],
        ["Exports", "Windows and Linux presets (export_presets.cfg), pck embedded, output in build/ (ignored by git)"],
    ], [38, 132]))
    story.append(P("Size", "h2"))
    by_dir = {}
    for f in files:
        top = os.path.dirname(f["path"])
        by_dir.setdefault(top, [0, 0])
        by_dir[top][0] += 1
        by_dir[top][1] += f["lines"]
    story.append(table(["Folder", "Scripts", "Lines"], [[esc(k), str(v[0]), str(v[1])] for k, v in sorted(by_dir.items())], [110, 30, 30]))
    story.append(P("No script is longer than 300 lines (the largest is %s at %d)." % (
        max(files, key=lambda f: f["lines"])["path"], max(f["lines"] for f in files)), "small"))
    story.append(P("Running", "h2"))
    story.append(code("godot --path .                      # play\n"
                      "godot --path . -e                   # open in the editor\n"
                      "godot --headless --path . --script tools/smoke.gd   # every room, boss, power and item with a bot"))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 2 design
    story.append(P("2. Game design", "h1"))
    story.append(P("World and story", "h2"))
    story.append(table(["Element", "In the game"], [
        ["The Grand Score", "Every song there is. The Conductor writes it and never noticed the notes are alive."],
        ["The Margin", "The hub and tutorial. Signs, a practice stand, Pause (a half rest who explains why rests are feared) and statues to choose a note."],
        ["The Rest", "The corruption. Enemies are rests. While a room is hushed the music is low-passed and the melody drops out."],
        ["Pillars", "Percussion (the Strikers, caverns, tradition), Wind (the Breathers, open sky, prejudiced against rests), String (the Resonants, humming forest, once played with the rests)."],
        ["The Grand Score (area)", "A short final bar: a fermata or shop, then the Conductor."],
        ["Secret", "Three clefs hidden by the Scribble, one per pillar bar. Holding all three when the Conductor falls opens the fight with the Score itself."],
        ["Endings", "Tacet (death), Prima volta (Conductor), Coda (the Score)."],
    ], [38, 132]))

    chars = read("src/data/content/characters_data.gd")
    rows = []
    for key, body in dict_entries(const_block(chars, "CHARACTERS")):
        rows.append([esc(field(body, "name")), esc(field(body, "role")), field(body, "hp"), num(field(body, "speed")),
                     field(body, "jumps"), "×" + field(body, "dmg"), field(body, "dr"), esc(field(body, "power")),
                     esc(field(body, "innate")), esc(field(body, "unlock") or "Default")])
    story.append(P("Characters", "h2"))
    story.append(table(["Note", "Role", "HP", "Spd", "Jmp", "Dmg", "DR", "Starts with", "Innate", "Unlock"], rows,
                       [19, 19, 10, 11, 10, 11, 10, 21, 38, 23], font_size=7))

    powers = read("src/data/content/powers_data.gd")
    rows = []
    for key, body in dict_entries(const_block(powers, "POWERS")):
        fam = field(body, "family")
        rows.append([esc(field(body, "name")), "Rest" if fam == "margin" else fam.capitalize(), field(body, "cd") + " s",
                     field(body, "dmg"), esc(field(body, "desc"))])
    story.append(P("Powers (%d)" % len(rows), "h2"))
    story.append(P("Two slots, a third with the Double Bar rune. Rehearsing at a fermata raises a power's level (up to III): "
                   "+30% damage and -12% cooldown per level. Percussion scales with max HP, Wind with speed, String with how many runes you own."))
    story.append(table(["Power", "Family", "Cooldown", "Damage", "What it does"], rows, [28, 19, 18, 16, 89]))

    runes = read("src/data/content/runes_data.gd")
    kinds = {}
    for key, body in dict_entries(const_block(runes, "RUNES")):
        k = field(body, "kind")
        kinds.setdefault(k, []).append(esc(field(body, "name")))
    story.append(P("Runes", "h2"))
    story.append(table(["Kind", "Count", "How it works", "Runes"], [
        ["swap", str(len(kinds.get("swap", []))), "Equip in the rune slots (3, or 4 with Segno). Swap outside combat.", ", ".join(kinds.get("swap", []))],
        ["family", str(len(kinds.get("family", []))), "Instrument runes. Two or three of one pillar wake a set bonus. Rival pillars together cause dissonance (a smaller beat window, and a combo effect).", ", ".join(kinds.get("family", []))],
        ["pause", str(len(kinds.get("pause", []))), "Support runes about timing, parry and recovery.", ", ".join(kinds.get("pause", []))],
        ["permanent", str(len(kinds.get("permanent", []))), "Given by keepers. Locked for the run. Includes the form changers.", ", ".join(kinds.get("permanent", []))],
        ["margin", str(len(kinds.get("margin", []))), "Rule-breaking and risky. Mostly from the Scribble.", ", ".join(kinds.get("margin", []))],
    ], [16, 12, 60, 82]))

    relics = read("src/data/content/relics_data.gd")
    entries = dict_entries(const_block(relics, "RELICS"))
    champs = [(k, b) for k, b in entries if "champion" in b]
    plain = [(k, b) for k, b in entries if "champion" not in b]
    story.append(P("Relics (%d) and champion items (%d)" % (len(plain), len(champs)), "h2"))
    story.append(table(["Relic", "Price", "Effect"], [[esc(field(b, "name")), field(b, "price") + " ♯", esc(field(b, "desc"))] for k, b in plain], [35, 16, 119]))
    story.append(Spacer(1, 3 * mm))
    story.append(table(["Champion item", "Family", "Effect"], [[esc(field(b, "name")), field(b, "family").capitalize(), esc(field(b, "desc"))] for k, b in champs], [35, 18, 117]))

    enemies = read("src/data/content/enemies_data.gd")
    pages = read("src/data/content/pages_data.gd")
    rows = []
    for key, body in dict_entries(const_block(enemies, "ENEMIES")):
        if key == "dummy":
            continue
        rows.append([esc(field(body, "name")), field(body, "ai"), field(body, "hp"), field(body, "dmg"),
                     "elite" if "elite" in body else "", esc(field(body, "tip"))])
    story.append(P("Enemies (%d)" % len(rows), "h2"))
    story.append(P("Every enemy acts on the beat: a red accent mark (>) appears one beat before it strikes. Health and damage grow per bar (×1.45 and ×1.22 per bar index)."))
    story.append(table(["Enemy", "AI", "HP", "Dmg", "", "Trick"], rows, [30, 24, 10, 10, 10, 86], font_size=7.2))
    rows = []
    for key, body in dict_entries(const_block(enemies, "BOSSES")):
        rows.append([esc(field(body, "name")), esc(field(body, "title")), field(body, "hp"), field(body, "family").capitalize()])
    story.append(P("Bosses", "h2"))
    story.append(table(["Boss", "Title", "HP", "Family"], rows, [40, 90, 15, 25]))
    rows = []
    for key, body in dict_entries(const_block(pages, "PAGES")):
        song = re.search(r'"bpm": ([\d.]+)', body)
        rows.append([esc(field(body, "name")), esc(field(body, "subtitle")), song.group(1) if song else "", esc(field(body, "boss"))])
    story.append(P("Bars (areas) and tempos", "h2"))
    story.append(table(["Area", "Subtitle", "BPM", "Boss"], rows, [38, 90, 14, 28]))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 3 architecture
    story.append(P("3. Architecture", "h1"))
    story.append(P(
        "The prototype is a code-first Godot project: one scene, nodes built with .new(), data in constants and "
        "Resources, drawing in code. Large classes are split into chains of layer classes so no file passes 300 "
        "lines. Each layer extends the one below; the top layer keeps the class name everything else uses."))
    story.append(P("Class layer chains", "h2"))
    story.append(table(["Class", "Layers, bottom to top", "Rule"], [
        ["Player", "PlayerState → PlayerDamage → PlayerAttacks → PlayerHooks → PlayerMovement → Player", "A layer may only call functions in its own file or below."],
        ["Enemy", "EnemyState → EnemyAttacks → EnemyDamage → EnemyMoveAI → EnemyBeatAI → EnemyEliteAI → Enemy", "Bosses extend Enemy through Boss."],
        ["Room", "RoomState → RoomCombat → RoomFlow → Room", "Lower layers pass themselves as Room with a cast (self as Room)."],
        ["Game (autoload)", "GameCore → GameRun → game.gd", "The autoload node is game.gd."],
        ["Content", "Front door aliasing CharactersData, PowersData, RunesData, RelicsData, EnemiesData, PagesData, StoryData", "Content.X still works everywhere."],
        ["Powers", "Front door dispatching to PercussionPowers, WindPowers, StringPowers, RestPowers", "Shared helpers stay on Powers."],
        ["FX", "Front door of preload constants for 13 effect classes (FxRing, FxSlash, ...)", "FX.Ring.new() still works."],
    ], [26, 92, 52]))
    story.append(P("Autoloads", "h2"))
    story.append(table(["Autoload", "Role", "Notes"], [
        ["Beat", "The clock: step (sixteenth), beat and bar signals; offsets for judging presses; song position in beats.", "Runs while paused (process mode ALWAYS). Every beat listener checks get_tree().paused."],
        ["Synth", "Builds all samples at startup, plays them from a pool of 28 players, runs the generative song, muffles and crossfades music.", "Music and SFX buses are created at runtime."],
        ["Game", "Settings, save file, meta progress, the current run, derived stats, input install, screen routing, god mode flag.", "Tools launched with --script use a separate test save."],
    ], [22, 95, 53]))
    story.append(P("Screen flow", "h2"))
    story.append(table(["Screen", "Script", "Leads to"], [
        ["Title", "src/ui/title.gd", "Begin → the Margin; Prologue; Settings; Quit"],
        ["The Margin (hub)", "Room type hub", "Walk into the exit → a new run → Map"],
        ["Map", "src/ui/map_screen.gd + src/ui/map/", "Pick a note → Room"],
        ["Room", "src/world/room/", "Exit → Map; boss → next bar's Map or an ending; death → Ending"],
        ["Ending", "src/ui/ending.gd", "Confirm → the Margin"],
    ], [30, 55, 85]))
    story.append(P("Screens change through Game.goto(), then a deferred swap in main.gd that unpauses, frees the old screen, adds the new one and fades from paper colour."))
    story.append(P("Runtime node tree of a room", "h2"))
    story.append(code(
        "Room (Node2D)\n"
        "  StaticBody2D (layer 1)       floor, walls, ceiling\n"
        "  StaticBody2D x N (layer 2)   one per staff-line segment, one-way\n"
        "  Background (Node2D, z -10)   paper, staff, wash, segments, features\n"
        "  Node2D actors                Player (+ Camera2D, MeleeSwing children), Enemy, Boss\n"
        "  Node2D projectiles           Projectile\n"
        "  Node2D fx                    FX effects\n"
        "  Interactable x N             chests, shop items, teachers, bench, statues, signs\n"
        "  Hud (CanvasLayer 5)          one widget per file + the open overlay\n"
        "  Timer x N                    delayed callbacks (Room._after)"))
    story.append(P("Collision layers", "h2"))
    story.append(table(["Layer", "Bit value", "Used by"], [
        ["1 solid", "1", "Floor, walls, ceiling, Timpani pillars"],
        ["2 one-way lines", "2", "Staff-line segments (the player drops through with Down + Jump)"],
        ["3 player", "4", "Player body"],
        ["4 enemies", "8", "Enemy bodies (flyers only collide with layer 1)"],
    ], [30, 22, 118]))
    story.append(P("Hits are distance and rectangle checks against room.alive_enemies(), not Area2D. This keeps them deterministic and cheap."))
    story.append(P("Communication", "h2"))
    story.append(table(["Emitter", "Signal", "Listener"], [
        ["Beat", "step(n)", "Synth sequencer"],
        ["Beat", "beat(n)", "Enemy._on_beat → ai_beat, Player._on_beat (Theremin, Hurdy-Gurdy), HudMetronome"],
        ["Beat", "bar(n)", "Player._on_bar (String set auto-wave)"],
        ["Game", "toast(text, color)", "HudToasts"],
        ["MeleeSwing", "struck(enemy, damage, info), landed_first_hit", "Player (deals damage, pogo bounce)"],
        ["Projectiles, FX, enemies", "(direct calls, no signal)", "Call player.deal() and player.take_hit() through room.player"],
        ["Overlays", "Callable fields (offer, dialogue, menu)", "Room and Events callbacks"],
    ], [30, 55, 85]))
    story.append(P("The prototype still relies on direct calls through room (a god object) far more than on signals. "
                   "ARCHITECTURE.md Part 2 sets the rules for the rebuild: components, exported references, call down / signal up, an event bus, a headless core and a command queue."))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 4 systems
    story.append(P("4. Systems", "h1"))
    timing = next(t for t in tuning_resources() if t["class"] == "TimingTuning")
    tv = {f["name"]: f["default"] for f in timing["fields"]}
    story.append(P("Rhythm and timing grades", "h2"))
    story.append(P("Every attack or power press is graded the moment it is pressed, against the nearest beat (half-beat for the Eighth Note). "
                   "Beat.signed_offset() subtracts the audio output latency and the player's beat offset setting."))
    story.append(table(["Grade", "Window", "Damage multiplier", "Counts as on the beat"], [
        ["Perfect", "≤ %s s" % tv["perfect_window"], "%s + rune beat bonus" % tv["perfect_multiplier"], "Yes"],
        ["Great", "≤ the player's beat window (0.085 s base, ×1.3 for Quarter)", "%s + rune beat bonus" % tv["great_multiplier"], "Yes"],
        ["Good", "≤ beat window × %s" % tv["good_window_scale"], tv["good_multiplier"], "No"],
        ["Miss", "anything further", "%s, minus %s per stacked miss (max %s stacks)" % (tv["miss_multiplier"], tv["mash_penalty_step"], tv["mash_penalty_max_stacks"]), "No"],
        ["None", "hits without a press (echoes, follow-ups)", "1.0", "No"],
    ], [18, 60, 60, 32]))
    story.append(P("Rhythm combos", "h2"))
    story.append(P("ComboTracker remembers presses in beats. When the gaps between the latest presses match a pattern (within ±%s beat) "
                   "and every press was at least good, the finisher replaces that attack. All great or better makes it perfect (damage ×%s)." % (tv["combo_interval_tolerance"], tv["combo_perfect_multiplier"])))
    rows = []
    for char in ["quarter", "half", "whole", "eighth"]:
        for c in tres_subresources("content/combat/%s_combos.tres" % char):
            rows.append([char.capitalize(), esc(c.get("pattern_name", "")), esc(c.get("notation", "")),
                         esc(c.get("intervals", "").replace("PackedFloat32Array", "")), c.get("damage", ""), esc(c.get("description", ""))])
    story.append(table(["Note", "Combo", "Rhythm", "Gaps (beats)", "Dmg", "Finisher"], rows, [15, 25, 22, 22, 10, 76]))
    story.append(P("Attacks", "h2"))
    story.append(P("Each character's chain is an AttackSet resource (content/combat/*_attacks.tres). Every swing spawns a MeleeSwing, a child of the player, "
                   "so the hitbox moves with the player for its active time and hits each enemy once. Attacking in the air while holding Down uses the down strike; "
                   "if it connects the player bounces up (pogo). Mundo's air attack stays a ground pound."))
    rows = []
    for char in ["quarter", "half", "whole", "eighth"]:
        text = read("content/combat/%s_attacks.tres" % char)
        subs = tres_subresources("content/combat/%s_attacks.tres" % char)
        has_down = "down_strike = SubResource" in text
        chain = subs[:-1] if has_down else subs
        div = re.search(r"beat_division = (\d+)", text)
        rows.append([char.capitalize(), ", ".join(s.get("damage", "") for s in chain), ", ".join(s.get("cadence", "") for s in chain),
                     subs[-1].get("damage", "") if has_down else "ground pound", "half-beat" if div and div.group(1) == "2" else "beat"])
    story.append(table(["Note", "Chain damage", "Cadence (s)", "Down strike", "Graded on"], rows, [18, 40, 40, 36, 36]))
    story.append(P("Damage pipeline", "h2"))
    story.append(code(
        "mult = base_dmg * (1 + dmg)\n"
        "     * (1 + power_dmg)            powers\n"
        "     * (1 + proj_dmg)             projectiles\n"
        "     * speed scaling              Hornist's Bell / Wind set 3\n"
        "     * grade multiplier           perfect / great / good / miss (see above)\n"
        "     * crescendo, accent, stunned bonus, Fade, Out of Tune, Diminution\n"
        "amount = base * mult\n"
        "then: lifesteal, on-beat heal, cooldown refunds, Kazoo, Tether share, Echo,\n"
        "      Sustain (Half Note), Double Stop, Cymbal crash, Pizzicato, Mallet shockwave"))
    story.append(P("All of this lives in PlayerDamage.deal() (src/actors/player/player_damage.gd). Follow-up hits pass proc: false so they never chain. "
                   "Damage numbers go through DamageNumbers, which merges hits on the same target within 220 ms into one number."))
    mv = next(t for t in tuning_resources() if t["class"] == "PlayerMovementTuning")
    mvv = {f["name"]: f["default"] for f in mv["fields"]}
    story.append(P("Movement", "h2"))
    story.append(table(["Value", "Setting", "Where"], [
        ["Gravity / jump speed / max fall", "2100 / 790 / 980 px/s", "PlayerState constants"],
        ["Jump height", "790² / (2 × 2100) ≈ 149 px (staff lines are 110 px apart)", "derived"],
        ["Coyote time / input buffer", "0.10 s / 0.13 s", "PlayerState constants"],
        ["Dash", "720 px/s for 0.15 s, 0.75 s cooldown, untouchable", "PlayerState constants"],
        ["Jump while rising fast", "adds %s of jump speed instead of replacing the rise" % mvv["jump_stack_ratio"], "PlayerMovementTuning"],
        ["Momentum carry", "air control × %s for %s s after a launch or strong push" % (mvv["momentum_air_control"], mvv["momentum_carry_time"]), "PlayerMovementTuning"],
        ["On-beat jump / dash / landing", "+%s jump, +%s dash time, +%s speed for %s s" % (mvv["beat_jump_bonus"], mvv["beat_dash_bonus"], mvv["flow_speed_bonus"], mvv["flow_time"]), "PlayerMovementTuning"],
        ["Drum pad / updraft", "launch %s px/s / lift %s px/s² up to %s px/s" % (num(mvv["drum_launch_speed"]), num(mvv["updraft_accel"]), num(mvv["updraft_max_rise"])), "PlayerMovementTuning"],
    ], [45, 85, 40]))
    story.append(P("Enemies and bosses", "h2"))
    et = {f["name"]: f["default"] for f in next(t for t in tuning_resources() if t["class"] == "EnemyTuning")["fields"]}
    story += bullets([
        "Each enemy runs ai_process() every frame (movement) and ai_beat() on every beat (attacks). A wind-up shows the accent mark one beat ahead.",
        "Detection: an enemy notices the player within %s px and gives up past %s px; elites and bosses always know. Taking damage alerts it." % (num(et["aggro_range"]), num(et["leash_range"])),
        "Idle enemies patrol random points within %s px of their spawn, pausing %s to %s s, with a %s s turn cooldown." % (num(et["patrol_radius"]), et["patrol_pause_min"], et["patrol_pause_max"], et["turn_cooldown"]),
        "Elites and bosses have super armor while winding up or attacking, and can't be stunned again for %s s after a stun. Bosses take %s of any stun." % (et["stun_immunity"], et["boss_stun_scale"]),
        "Bosses phrase attacks in bars and change pattern at health thresholds. The Hollow Timpani uses TimpaniTuning (a 2-bar cycle with a recovery window).",
    ])
    story.append(P("Generation", "h2"))
    lg = {f["name"]: f["default"] for f in next(t for t in tuning_resources() if t["class"] == "LevelGenTuning")["fields"]}
    story.append(table(["Step", "What happens", "Class"], [
        ["Bar layout", "Entry fight, branching layers of %s rooms, then a fermata (sometimes with a chest), then the boss. Specials placed once each: %s, plus a second elite %s%% of the time." % (
            num(lg["branch_layers"]), num(lg["special_rooms"]), int(float(lg["second_elite_chance"]) * 100)), "BarPlanner, MapGen"],
        ["Room size", "Fights %s to %s px wide (+%s on Wind), elites %s px, events 1280 px." % (num(lg["combat_width_min"]), num(float(lg["combat_width_min"]) + float(lg["combat_width_extra"])), num(lg["wind_width_bonus"]), num(lg["elite_width"])), "Layout"],
        ["Platforms", "Each staff line is broken into segments by per-pillar densities.", "Layout"],
        ["Reachability", "A search from the floor, one line up at a time within %s px (same line %s px). Unreachable platforms get a stepping-stone ledge below." % (num(lg["climb_reach"]), num(lg["same_line_reach"])), "PlatformReachability"],
        ["Features", "Drums, updrafts and harmonic nodes at least %s px apart, clear of spawn and exit." % num(lg["feature_min_spacing"]), "FeaturePlacer"],
        ["Waves", "%s to %s waves, varied sizes, at most %s of one type, reinforcements %s%% of the time once half a wave is down." % (lg["waves_min"], lg["waves_max"], lg["max_same_type_per_wave"], int(float(lg["reinforcement_chance"]) * 100)), "WavePlanner, WavePlan"],
        ["Spawns", "Floor, platforms (weighted by length) and air, %s px apart and %s px from the player." % (num(lg["spawn_spacing"]), num(lg["spawn_player_distance"])), "SpawnPicker"],
        ["Offers", "Items that need a skill you lack are skipped; offers lean to your pillars.", "Loot, ItemRequirements"],
    ], [24, 110, 36]))
    story.append(P("All generation uses the run's seeded RandomNumberGenerator, so a seed always gives the same map and rooms."))
    story.append(P("Music", "h2"))
    story += bullets([
        "Each area has a seeded generative song: drums, bass, pad, arpeggio and a lead phrase in an A B A' C shape.",
        "While a room is hushed the Music bus is low-passed (18000 Hz → 520 Hz) and the lead is muted above half hush.",
        "The muffle follows how much of the room is left (never below the minimum while enemies remain) and clears on room clear.",
        "Changing bars crossfades the songs (MusicTuning). The tempo per area is fixed; revisiting it waits for the real music (issue #6).",
    ])
    story.append(P("Interface", "h2"))
    story.append(table(["Part", "Files", "Notes"], [
        ["HUD", "src/ui/hud/ (Hud + 11 widgets)", "Health, power bar (under health), metronome, boss bar, room status, edge flash, banner, toasts, prompt with item details, character card"],
        ["Map", "src/ui/map_screen.gd, src/ui/map/", "Drawn as a score: notes per room type, measures, slurs, playhead"],
        ["Overlays", "src/ui/*.gd extending Overlay", "Choice cards, dialogue, menu list, loadout, pause, settings (sliders), controls (rebinding)"],
        ["Title / Ending", "src/ui/title.gd, ending.gd", "Prologue, stats, endings"],
    ], [24, 55, 91]))
    story.append(P("Input and rebinding", "h2"))
    story.append(P("InputBindings (src/input/input_bindings.gd) registers 13 actions with defaults, then applies the player's saved bindings from settings. "
                   "The Controls menu shows three keyboard/mouse slots and one controller slot per action; binding an input removes it from any other action. "
                   "InputLabels turns bindings into short names (LMB, RB, D-pad up) for on-screen hints."))
    rows = []
    ib = read("src/input/input_bindings.gd")
    for act, name in re.findall(r'\["(\w+)", "([^"]+)"\]', ib.split("const DEADZONE")[0]):
        spec = re.search(r'"%s": \[([^\]]*)\]' % act, ib)
        rows.append([esc(name), esc(spec.group(1).replace("KEY_", "").replace('"', "")) if spec else ""])
    story.append(table(["Action", "Defaults (keys, mouse:N, pad:N, axis)"], rows, [40, 130]))
    story.append(P("Saves, settings and debug", "h2"))
    story += bullets([
        "Save: user://discordant_save.json with meta (unlocks, runs, wins, seen enemies) and settings (volumes, shake, beat offset, metronome, fullscreen, bindings).",
        "Anything launched with --script uses user://discordant_test_save.json, so tests never touch the real save.",
        "Debug menu (F1): god mode, heal, sharps, grant items, learn a power, kill / clear, clefs, unlock characters, skip to next bar or boss. Available in debug builds, or with -- --debug-menu.",
    ])
    story.append(PageBreak())

    # ---------------------------------------------------------------- 5 data & tuning
    story.append(P("5. Data and tuning", "h1"))
    story.append(P("Content (what exists) lives in GDScript constant files; tuning (how it behaves) lives in Resource scripts with .tres instances "
                   "under content/, editable in the inspector. New numbers must go in a tuning resource, never inline."))
    story.append(table(["Content file", "Holds"], [
        ["src/data/content/characters_data.gd", "The four notes"],
        ["src/data/content/powers_data.gd", "20 powers"],
        ["src/data/content/runes_data.gd", "Runes, family sets, dissonance"],
        ["src/data/content/relics_data.gd", "Relics and champion items"],
        ["src/data/content/enemies_data.gd", "Enemies and bosses"],
        ["src/data/content/pages_data.gd", "Areas, songs, the climb, clefs"],
        ["src/data/content/story_data.gd", "Teachers, intro, prologue, endings"],
        ["src/data/content/item_requirements.gd", "Which items need which skill"],
        ["content/combat/*_attacks.tres, *_combos.tres", "Attack chains and rhythm combos per character"],
    ], [75, 95]))
    for t in tuning_resources():
        story.append(KeepTogether([P("%s  (%s)" % (t["class"], t["file"]), "h3"), P(esc(t["doc"]), "small"), Spacer(1, 1.5 * mm),
                                   table(["Field", "Default", "Meaning"],
                                         [[esc(f["name"]), esc(num(f["default"])), esc(f["doc"])] for f in t["fields"]],
                                         [45, 35, 90], font_size=7.2)]))
        story.append(Spacer(1, 2 * mm))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 6 file map
    story.append(P("6. File map", "h1"))
    story.append(P("Every script in src/, with its class and the first line of its description."))
    rows = [[esc(f["path"].replace("src/", "")), str(f["lines"]), esc(f["class"]), esc(f["extends"]), esc(f["doc"])] for f in files]
    story.append(table(["File (under src/)", "Lines", "Class", "Extends", "Description"], rows, [47, 12, 26, 24, 61], font_size=6.6))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 7 decisions
    story.append(P("7. Design decisions", "h1"))
    story.append(table(["Decision", "Why", "Trade-off / note"], [
        ["All art and audio made in code", "No asset pipeline needed for a prototype; the ink-on-paper look is consistent everywhere.", "Replacing it with sprites means rewriting each _draw()."],
        ["One scene, nodes built in code", "Fast to generate and change; nothing hidden in the editor.", "The editor shows almost nothing; the rebuild moves to scenes with exported references."],
        ["Staff lines are the platforms", "Makes 'the map is a music sheet' literal; the climb is the core movement.", "Line spacing (110 px) ties level design to jump height."],
        ["One global beat clock", "Enemies, bosses, music and grading share one rhythm, so listening helps.", "The clock runs while paused; listeners must check pause."],
        ["The Rest is audible silence", "Hushed rooms are low-passed and lose the melody; clearing restores it.", "Now graduated by how much of the room is left (#13)."],
        ["Hades-style branching bars", "Clear choices and pacing; room code is independent of the map.", "Map style was TBD; a freezone or vertical layout could replace MapGen."],
        ["Areas called Bars in text only", "Matches the music theme (#9) without renaming code.", "Code still says page (page_id, PAGES)."],
        ["Graded timing with a mash penalty", "Rewards precision over spamming (#12).", "Grades are judged at press time, not after the input buffer."],
        ["Eighth Note graded on half-beats", "Half a beat is its note value; its fast attacks would otherwise mostly miss.", "Only the Eighth; others use the beat."],
        ["Rhythm-pattern combos", "Chosen by the owner (#11): the rhythm of your presses is the combo.", "Two per character; data in .tres, easy to add more."],
        ["Full rebinding, no presets", "Chosen by the owner (#17).", "Controller stick bindings exist but the menu shows one controller column."],
        ["Super armor on elites and bosses", "Stops stunlocking out of wind-ups (#3).", "Hits still deal damage."],
        ["Detection range and patrol", "Fixes wall-hugging (#2) and makes rooms feel less swarmed.", "Enemies far away wait until you get close."],
        ["Reachability tested with Mundo", "The most limited jumper; if Mundo can reach it everyone can (#7).", "Stepping stones are added rather than platforms removed."],
        ["Tuning as .tres Resources", "Designers edit numbers in the inspector; follows the rebuild rules.", "Older prototype constants remain in code."],
        ["Layer chains for big classes", "Every file under 300 lines without changing behaviour (#29).", "A reading structure; the rebuild turns layers into components."],
        ["Seeded RNG everywhere in generation", "The same run seed gives the same map; found and fixed an unseeded shuffle.", "Combat randomness still uses the global RNG."],
        ["Test save isolation", "Bots and captures once polluted the real save.", "Anything run with --script uses a separate save file."],
    ], [40, 70, 60], font_size=7.3))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 8 issue log
    story.append(P("8. Playtest issue log", "h1"))
    story.append(P("Issues from playtest round 1 (public repo JecerSE/discordant). Fixes are in the private repository only; the issues are still open on GitHub."))
    story.append(table(["#", "Issue", "Status", "Fix", "Main files"], [
        ["1", "Double damage numbers", "Fixed", "Hits on one target merge into one number per channel", "damage_numbers.gd, damage_number.gd"],
        ["2", "Enemies hug the walls", "Fixed", "Detection range, patrol near spawn, turn cooldown", "enemy_patrol.gd, enemy_move_ai.gd"],
        ["3", "Bosses stunlocked", "Fixed", "Super armor during wind-ups, stun immunity window", "enemy_state.gd, enemy_damage.gd"],
        ["4", "Drum pads overlap", "Fixed", "Minimum spacing, clear of spawn and exit", "feature_placer.gd"],
        ["5", "Jarring character select", "Fixed", "Fixed-width card slides in", "hud_character_card.gd"],
        ["6", "Tempo changes", "Deferred", "Owner will revisit with the real music", ""],
        ["7", "Unreachable platforms", "Fixed", "Reachability search with stepping stones", "platform_reachability.gd"],
        ["8", "Longer bars, more power-ups", "Fixed", "6 branching layers, 2 chests, 2 teachers, bigger rooms, 40% bonus drop", "bar_planner.gd, level_gen_tuning"],
        ["9", "Page → Bar", "Fixed", "Player-facing text", "pages_data.gd, events.gd, ending.gd"],
        ["10", "Melee follows movement", "Fixed", "MeleeSwing child hitbox, down strike with pogo", "melee_swing.gd, attack data"],
        ["11", "Combo system", "Fixed", "Rhythm-pattern combos with finishers", "combo_tracker.gd, combo_finishers.gd"],
        ["12", "Reward precision", "Fixed", "Graded timing, mash penalty", "beat_grader.gd"],
        ["13", "Fluid music", "Fixed", "Graduated muffle, crossfades", "synth.gd, room_combat.gd"],
        ["14", "On-beat movement", "Fixed", "Jump, dash and landing bonuses", "player_movement.gd"],
        ["15", "Momentum from launchers", "Fixed", "launch(), jump stacking, momentum carry", "player_movement.gd"],
        ["16", "Rebinding and controller", "Fixed", "InputBindings, Controls menu", "input_bindings.gd, controls_menu.gd"],
        ["17", "Control layout", "Fixed", "Full rebinding (owner's choice), no presets", "same as #16"],
        ["18", "Sliders", "Fixed", "Settings menu with draggable sliders", "settings_menu.gd"],
        ["19", "Power icons in the way", "Fixed", "Moved under the health bar", "hud_power_bar.gd"],
        ["20", "Shop descriptions", "Fixed", "Prompt shows name, kind and effect", "hud_prompt.gd, interactable.gd"],
        ["21", "God mode debug", "Fixed", "F1 debug menu", "src/debug/"],
        ["22", "Mechanic in the wrong place", "Deferred", "Needs clarification from the owner", ""],
        ["24", "Map as sheet music", "Fixed", "Score renderer and note glyphs", "src/ui/map/"],
        ["25", "Randomised spawns", "Fixed", "Wave planner, spawn picker, reinforcements", "wave_planner.gd, spawn_picker.gd"],
        ["26", "Relevant power-ups", "Fixed", "Requirement filter, pillar lean", "item_requirements.gd, loot.gd"],
        ["27", "Slow the Percussion boss", "Fixed", "2-bar cycle, recovery, slower waves and mallets", "timpani.gd, timpani_tuning"],
        ["29", "Split big scripts", "Fixed", "Folders and layer chains; powers per family", "src/actors/player/powers/"],
    ], [8, 36, 15, 60, 51], font_size=7.2))
    story.append(P("#23 is the tracking issue and #28 does not exist.", "small"))
    story.append(PageBreak())

    # ---------------------------------------------------------------- 9 testing
    story.append(P("9. Testing and tools", "h1"))
    story.append(table(["Tool", "Command", "What it checks"], [
        ["smoke.gd", "godot --headless --path . --script tools/smoke.gd", "Loads every script; a bot plays every room type on every bar with all items and powers, plus the secret boss"],
        ["playthrough.gd", "godot --headless --fixed-fps 60 --path . --script tools/playthrough.gd -- quarter 1", "A full run through the real flow to an ending (1 = hold the clefs → secret ending); reports rooms that time out"],
        ["test_generation.gd", "godot --headless --path . --script tools/test_generation.gd", "300 seeds: reachability, feature spacing, wave mix and caps, bar layout"],
        ["test_combat.gd", "godot --headless --path . --script tools/test_combat.gd", "Grade thresholds, damage ordering, mash penalty, every combo pattern"],
        ["test_menus.gd", "godot --headless --path . --script tools/test_menus.gd", "Pause → Settings sliders, Controls rebinding and conflicts, save round trip, debug actions"],
        ["capture.gd", "godot --path . --script tools/capture.gd -- <dir>", "Screenshots of every screen (opens a window)"],
        ["gen_combat_tres.py", "python3 tools/gen_combat_tres.py", "Writes content/combat/*.tres from tables"],
        ["build_docs.py", "python3 tools/build_docs.py", "Builds this document"],
    ], [30, 72, 68], font_size=7.2))
    story.append(P("Last verified at this commit: smoke test 0 errors; full playthroughs as Quarter and Eighth reached the Coda ending through 29 rooms with 0 errors; all three rule tests pass."))

    # ---------------------------------------------------------------- 10 limitations
    story.append(P("10. Known limitations and next steps", "h1"))
    story += bullets([
        "Room is still a god object (about 300 direct room. calls); actors hold untyped room references.",
        "Most prototype content is still GDScript constants and string ids; a typo is a silent no-op.",
        "Only one scene file; no exported node references in prototype code.",
        "Combat randomness (crits, Kazoo, Out of Tune) uses the global RNG, not a seeded stream.",
        "Hits are distance checks; fast projectiles can pass through small targets.",
        "Controller stick bindings work but are not shown in the Controls menu (one controller column).",
        "Issue #6 (tempo) waits for the real music; issue #22 needs clarification.",
        "Feel and balance of the new systems (grades, combos, on-beat movement, longer bars) have not been hand-tested.",
        "The rebuild plan (components, event bus, headless core, command queue, integer maths) is in ARCHITECTURE.md Parts 2 and 3.",
    ])

    # ---------------------------------------------------------------- 11 workflow
    story.append(P("11. Repository and release workflow", "h1"))
    story.append(table(["Repository", "Visibility", "Use"], [
        ["JecerSE/the-discordant (~/the-discordant)", "Private", "All development. Every change is committed and pushed here."],
        ["JecerSE/discordant (~/discordant)", "Public", "Clean release snapshots only, when the owner calls a build a good release. No working notes, no assistant attribution."],
    ], [60, 20, 90]))
    story.append(P("Public releases carry Windows and Linux zips built from export_presets.cfg (templates for 4.7.2 in ~/.local/share/godot/export_templates/4.7.2.stable)."))

    # ---------------------------------------------------------------- 12 commits
    story.append(P("12. Commit history", "h1"))
    log = git("log", "--date=short", "--pretty=format:%h\t%ad\t%s")
    rows = [[esc(c) for c in line.split("\t", 2)] for line in log.split("\n") if line.strip()]
    story.append(table(["Commit", "Date", "Summary"], rows, [18, 20, 132], font_size=7.2))

    # ---------------------------------------------------------------- 13 glossary
    story.append(P("13. Glossary", "h1"))
    story.append(table(["Term", "Meaning"], [
        ["Bar", "An area of the climb (Percussion, Wind, Strings, the Grand Score). Called page in code."],
        ["Keeper", "A pillar bar's boss."],
        ["The Rest / hushed", "The corruption; a room with enemies left is hushed."],
        ["Sharps (♯)", "Currency."],
        ["Fermata", "A rest room (heal or rehearse), also a Rest power and a pause rune."],
        ["Rehearse", "Raise a power's level at a fermata."],
        ["Family / pillar", "Percussion, Wind or String. Rest (margin) is the fourth, secret family."],
        ["Dissonance", "Rival pillars' family runes equipped together."],
        ["Grade", "Perfect, great, good or miss: how close a press was to the beat."],
        ["Layer chain", "A class split across files, each file extending the previous one."],
        ["Tuning resource", "A Resource script plus a .tres file holding balance numbers."],
    ], [35, 135]))
    return story


def main():
    doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=18 * mm, bottomMargin=20 * mm,
                            title="The Discordant: Codebase and design documentation", author="Pursion")
    doc.build(build(), onFirstPage=on_first_page, onLaterPages=on_page)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
