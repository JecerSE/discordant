"""Writes content/combat/*.tres from the tables below. Run from the project root:
python3 tools/gen_combat_tres.py
The .tres files are the source of truth once written; this script is only a
convenient way to create them without typos."""

ATTACKS = {
    "quarter": {"reset": 0.7, "pogo": 640.0, "steps": [
        dict(damage=10.0, cadence=0.26, offset=(40, -6), size=(80, 56), knock=(160, -90), slash_radius=50.0),
        dict(damage=10.0, cadence=0.26, offset=(40, -6), size=(80, 56), knock=(160, -90), slash_radius=50.0, slash_flip=True),
        dict(damage=17.0, cadence=0.34, offset=(40, -6), size=(80, 56), knock=(380, -220), slash_radius=60.0)],
        "down": dict(damage=12.0, cadence=0.3, offset=(0, 34), size=(56, 70), knock=(0, 380), slash_radius=46.0)},
    "half": {"reset": 0.8, "pogo": 640.0, "steps": [
        dict(damage=16.0, cadence=0.4, offset=(46, -6), size=(92, 66), knock=(260, -120), slash_radius=58.0),
        dict(damage=22.0, cadence=0.4, offset=(46, -6), size=(92, 66), knock=(260, -120), slash_radius=58.0, slash_flip=True)],
        "down": dict(damage=19.0, cadence=0.42, offset=(0, 36), size=(64, 76), knock=(0, 400), slash_radius=52.0)},
    "eighth": {"reset": 0.45, "pogo": 700.0, "division": 2, "steps": [
        dict(damage=7.0, cadence=0.16, active_time=0.07, offset=(38, -4), size=(68, 46), knock=(140, -60), lunge=520.0, slash_radius=40.0),
        dict(damage=7.0, cadence=0.16, active_time=0.07, offset=(38, -4), size=(68, 46), knock=(140, -60), lunge=520.0, slash_radius=40.0, slash_flip=True),
        dict(damage=7.0, cadence=0.16, active_time=0.07, offset=(38, -4), size=(68, 46), knock=(140, -60), lunge=520.0, slash_radius=40.0),
        dict(damage=12.0, cadence=0.16, active_time=0.07, offset=(38, -4), size=(68, 46), knock=(140, -60), lunge=520.0, slash_radius=40.0, slash_flip=True)],
        "down": dict(damage=9.0, cadence=0.2, active_time=0.08, offset=(0, 30), size=(50, 64), knock=(0, 340), slash_radius=38.0)},
    # Mundo's air attack stays the ground pound, so it has no down strike.
    "whole": {"reset": 0.0, "pogo": 0.0, "steps": [
        dict(damage=24.0, cadence=0.56, active_time=0.12, shape=1, offset=(26, 0), size=(78, 0), knock=(420, -160), slash_radius=0.0)],
        "down": None},
}

COMBOS = {
    "quarter": [
        dict(pattern_name="Common Time", notation="♩ ♩ ♩ ♩", intervals=[1, 1, 1], finisher="common_time", damage=34.0,
             description="Four quarters in a row: a wide crescent plus a soundwave."),
        dict(pattern_name="Syncopated Run", notation="♪ ♪ ♩", intervals=[0.5, 0.5], finisher="syncopated_run", damage=24.0,
             description="Two eighths then a quarter: dash through everything ahead."),
    ],
    "half": [
        dict(pattern_name="Cut Time", notation="𝅗𝅥 𝅗𝅥 𝅗𝅥", intervals=[2, 2], finisher="cut_time", damage=40.0,
             description="Three halves: two rings, the second one beat after the first."),
        dict(pattern_name="Dotted Rise", notation="♩. ♪ ♩", intervals=[1.5, 0.5], finisher="dotted_rise", damage=30.0,
             description="Dotted quarter, eighth, quarter: a rising slash that launches enemies."),
    ],
    "whole": [
        dict(pattern_name="Semibreve", notation="𝅝 𝅝", intervals=[4], finisher="semibreve", damage=48.0,
             description="Two strikes a whole bar apart, nothing between: a quake that stuns."),
        dict(pattern_name="Stomp Time", notation="♩ ♩ ♩", intervals=[1, 1], finisher="stomp_time", damage=30.0,
             description="Three quarters: a heavy ring that stuns everything near."),
    ],
    "eighth": [
        dict(pattern_name="Eighth Run", notation="♪ ♪ ♪ ♪ ♪", intervals=[0.5, 0.5, 0.5, 0.5], finisher="eighth_run", damage=9.0,
             description="Five eighths in a row: a flurry of six quick cuts."),
        dict(pattern_name="Swing Cut", notation="♪ ♩ ♪", intervals=[0.5, 1], finisher="swing_cut", damage=26.0,
             description="Eighth, quarter, eighth: blink behind the nearest enemy and cut."),
    ],
}


def val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, tuple):
        return "Vector2(%s, %s)" % v
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, int):
        return str(v)
    return '"%s"' % v


def attack_tres(char, spec):
    subs, ids = [], []
    for i, st in enumerate(spec["steps"]):
        sid = "step_%d" % (i + 1)
        ids.append(sid)
        subs.append((sid, st))
    if spec["down"]:
        subs.append(("down_strike", spec["down"]))
    out = ['[gd_resource type="Resource" script_class="AttackSet" load_steps=%d format=3]' % (len(subs) + 3), "",
           '[ext_resource type="Script" path="res://src/data/combat/attack_set.gd" id="1"]',
           '[ext_resource type="Script" path="res://src/data/combat/attack_step.gd" id="2"]', ""]
    for sid, st in subs:
        out += ['[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("2")']
        out += ["%s = %s" % (k, val(v)) for k, v in st.items()]
        out.append("")
    out += ["[resource]", 'script = ExtResource("1")',
            "steps = Array[ExtResource(\"2\")]([%s])" % ", ".join('SubResource("%s")' % i for i in ids),
            "combo_reset = %s" % repr(spec["reset"]), "pogo_speed = %s" % repr(spec["pogo"]),
            "beat_division = %d" % spec.get("division", 1)]
    if spec["down"]:
        out.append('down_strike = SubResource("down_strike")')
    return "\n".join(out) + "\n"


def combo_tres(char, pats):
    out = ['[gd_resource type="Resource" script_class="ComboSet" load_steps=%d format=3]' % (len(pats) + 3), "",
           '[ext_resource type="Script" path="res://src/data/combat/combo_set.gd" id="1"]',
           '[ext_resource type="Script" path="res://src/data/combat/combo_pattern.gd" id="2"]', ""]
    ids = []
    for i, p in enumerate(pats):
        sid = "combo_%d" % (i + 1)
        ids.append(sid)
        out += ['[sub_resource type="Resource" id="%s"]' % sid, 'script = ExtResource("2")',
                'pattern_name = "%s"' % p["pattern_name"], 'notation = "%s"' % p["notation"],
                "intervals = PackedFloat32Array(%s)" % ", ".join(str(x) for x in p["intervals"]),
                'finisher = &"%s"' % p["finisher"], "damage = %s" % repr(p["damage"]),
                'description = "%s"' % p["description"], ""]
    out += ["[resource]", 'script = ExtResource("1")',
            "patterns = Array[ExtResource(\"2\")]([%s])" % ", ".join('SubResource("%s")' % i for i in ids)]
    return "\n".join(out) + "\n"


for char, spec in ATTACKS.items():
    open("content/combat/%s_attacks.tres" % char, "w").write(attack_tres(char, spec))
for char, pats in COMBOS.items():
    open("content/combat/%s_combos.tres" % char, "w").write(combo_tres(char, pats))
print("wrote", len(ATTACKS) + len(COMBOS), "files")
