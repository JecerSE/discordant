class_name EnemyArt
## How each enemy's body is drawn, in code. Enemy draws it through RenderAdapter (sprites
## when "enemy_<id>" is switched on in content/art/render_flags.tres, this code otherwise),
## and pipeline/render_placeholders.gd renders these same functions into placeholders.
##
## Sprites per enemy: "enemy_<id>" is the body drawn in white, tinted at draw time with the
## hit / stun / frozen ink colour; "enemy_<id>_accent" is the untinted family-coloured part
## (the tether ring, gust lines); "enemy_<id>_crown" is an elite's crown. The reed and the
## practice stand are two-tone, so they get one sprite per ink colour instead
## ("enemy_<id>_<tint>"). Eyes, haze, auras, tethers and marks stay in code: they follow
## facing, time or state. Reads no game state and uses no randomness.

## Enemies drawn with another rest's glyph (the rest use their own id).
const GLYPHS := {
	"timpanist": "snare_rest", "cymbalist": "half_rest", "piper": "eighth_rest",
	"hornist": "gust_rest", "violist": "sixteenth_rest", "cellist": "quarter_rest",
	"rim_guard": "half_rest", "bandleader": "quarter_rest", "dasher": "eighth_rest",
	"phantom": "eighth_rest", "motif_rest": "sixteenth_rest", "binder_rest": "tether_rest",
	"warden_rest": "echo_rest",
}
## Drawn by their own code, not a rest glyph.
const CUSTOM := ["breath_well", "dummy"]
## Ink colours a body can be drawn in (see Enemy._draw), for the two-tone custom bodies.
const TINTS := ["ink", "hit", "stun", "frozen"]


static func glyph_for(id: String) -> String:
	return GLYPHS.get(id, id)


## The ink colour Enemy._draw picks for its state, by name.
static func tint_colour(tint: String) -> Color:
	match tint:
		"hit": return Pal.BLOOD
		"stun": return Pal.INK.lerp(Pal.HUSH, 0.5)
		"frozen": return Pal.INK.lerp(Pal.MARGIN, 0.35)
	return Pal.INK


static func body(ci: CanvasItem, id: String, r: float, t: float, col := Color.WHITE) -> void:
	Glyph.rest(ci, glyph_for(id), Vector2.ZERO, r * 0.95, col, t, Color(0, 0, 0, 0), Glyph.REST_BODY)


static func accent(ci: CanvasItem, id: String, r: float, family: String, t: float) -> void:
	Glyph.rest(ci, glyph_for(id), Vector2.ZERO, r * 0.95, Color.WHITE, t, Pal.family_color(family), Glyph.REST_ACCENT)


static func crown(ci: CanvasItem, r: float, family: String) -> void:
	var crown_pts := PackedVector2Array([Vector2(-r * 0.6, -r - 6), Vector2(-r * 0.4, -r - 18), Vector2(-r * 0.12, -r - 9),
		Vector2(0, -r - 22), Vector2(r * 0.12, -r - 9), Vector2(r * 0.4, -r - 18), Vector2(r * 0.6, -r - 6)])
	ci.draw_polyline(crown_pts, Pal.family_color(family), 2.5, true)


## The breath reed at rest (its breathing is a horizontal scale; the rising puffs stay code).
static func reed(ci: CanvasItem, r: float, col: Color) -> void:
	var h := r * 2.4
	ci.draw_rect(Rect2(-r * 0.4, -h * 0.6, r * 0.8, h), Pal.WIND.lerp(Pal.PAPER_DARK, 0.4))
	ci.draw_rect(Rect2(-r * 0.4, -h * 0.6, r * 0.8, h), col, false, 3.0)
	for i in 3:
		ci.draw_circle(Vector2(0, -h * 0.4 + i * h * 0.25), 3.0, col)


static func practice_stand(ci: CanvasItem, r: float, col: Color) -> void:
	ci.draw_line(Vector2(0, -r), Vector2(0, r), Pal.INK_SOFT, 4.0)
	ci.draw_line(Vector2(-r * 0.7, r), Vector2(r * 0.7, r), Pal.INK_SOFT, 4.0)
	ci.draw_circle(Vector2(0, -r * 0.4), r * 0.7, Pal.PAPER_DARK)
	ci.draw_arc(Vector2(0, -r * 0.4), r * 0.7, 0, TAU, 20, col, 3.0, true)
	ci.draw_arc(Vector2(0, -r * 0.4), r * 0.35, 0, TAU, 16, col, 2.0, true)


## How long one loop of a glyph's animation lasts (s), or 0 if it is still.
static func body_period(id: String) -> float:
	match glyph_for(id):
		"quarter_rest", "tether_rest": return TAU / 6.0
		"echo_rest": return 1.0
	return 0.0


## The accent layer's loop length (s): 0 for a still accent, -1 when there is none.
static func accent_period(id: String, r: float) -> float:
	match glyph_for(id):
		"gust_rest": return r * 0.95 * 1.6 / 120.0
		"tether_rest": return 0.0
	return -1.0


## Every enemy placeholder, for the generator.
static func placeholders() -> Dictionary:
	var out := {}
	var defs: Dictionary = load("res://src/data/content/enemies_data.gd").ENEMIES
	for id in defs:
		var e: Dictionary = defs[id]
		var r: float = e.r
		var fam: String = e.get("family", "")
		var eid: String = id
		if eid in CUSTOM:
			for tint in TINTS:
				var col := tint_colour(tint)
				if eid == "breath_well":
					out["enemy_%s_%s" % [eid, tint]] = func(ci): reed(ci, r, col)
				else:
					out["enemy_%s_%s" % [eid, tint]] = func(ci): practice_stand(ci, r, col)
			continue
		var bp := body_period(eid)
		if bp > 0.0:
			out["enemy_" + eid] = {"draw": func(ci, t): body(ci, eid, r, t), "frames": 12, "period": bp,
				"tint": Pal.INK, "check": func(ci, t): body(ci, eid, r, t, Pal.INK)}
		else:
			out["enemy_" + eid] = {"draw": func(ci, _t): body(ci, eid, r, 0.0), "tint": Pal.INK,
				"check": func(ci, _t): body(ci, eid, r, 0.0, Pal.INK)}
		var ap := accent_period(eid, r)
		if ap >= 0.0:
			out["enemy_%s_accent" % eid] = {"draw": func(ci, t): accent(ci, eid, r, fam, t),
				"frames": 8 if ap > 0.0 else 1, "period": ap if ap > 0.0 else 1.0}
		if e.get("elite", false):
			out["enemy_%s_crown" % eid] = func(ci): crown(ci, r, fam)
	return out
