class_name FxArt
## The effects whose look is fixed or depends only on their own clock, drawn in code. Each
## effect draws through RenderAdapter when its "fx_<name>" key is on in render_flags.tres,
## and pipeline/render_placeholders.gd renders these same functions (animated ones as frame
## strips). Effects whose size, direction, endpoints or scatter vary per instance (slash,
## ring, shockwave, column, pillar, trail, splat, projectiles) stay procedural.
## Reads no game state and uses no randomness.

const SPAWN_MARK_LIFE := 0.75


static func pickup(ci: CanvasItem, kind: String) -> void:
	if kind == "sharp":
		Glyph.sharp(ci, Vector2.ZERO, 9.0, Pal.GOLD)
	else:
		ci.draw_circle(Vector2.ZERO, 7.0, Pal.HEAL)
		ci.draw_circle(Vector2.ZERO, 3.0, Pal.PAPER)


## A Ghost Note decoy of the player's note, pulsing.
static func decoy(ci: CanvasItem, kind: String, t: float) -> void:
	var a := 0.35 + 0.25 * sin(t * 12.0)
	Glyph.note(ci, kind, Vector2.ZERO, 1.0, 13.0, Color(Pal.MARGIN, a))


## Where a Rest is about to appear, over the mark's life.
static func spawn_mark(ci: CanvasItem, elite: bool, t: float) -> void:
	var k := t / SPAWN_MARK_LIFE
	var r := (30.0 if elite else 20.0) * (0.3 + k)
	ci.draw_circle(Vector2.ZERO, r, Color(Pal.HUSH, 0.25 + 0.4 * k))
	ci.draw_arc(Vector2.ZERO, r * 1.6 * (1.0 - k) + r, 0, TAU, 24, Color(Pal.HUSH, 0.6), 2.0, true)


## The Tempest's tornado at full strength (its end fade is a tint).
static func tornado(ci: CanvasItem, t: float) -> void:
	for i in 7:
		var y := -i * 26.0
		var w := 20.0 + i * 13.0
		var ph := t * 9.0 + i
		ci.draw_arc(Vector2(sin(ph) * 8.0, y), w, ph, ph + PI * 1.3, 16, Color(Pal.WIND, 0.75), 3.0, true)


static func placeholders() -> Dictionary:
	var out := {
		"fx_pickup_sharp": func(ci): pickup(ci, "sharp"),
		"fx_pickup_heal": func(ci): pickup(ci, "heal"),
		"fx_tornado": {"draw": func(ci, t): tornado(ci, t), "frames": 16, "period": TAU / 9.0},
	}
	for elite in [false, true]:
		var e: bool = elite
		out["fx_spawn_mark" + ("_elite" if e else "")] = {"draw": func(ci, t): spawn_mark(ci, e, t), "frames": 12, "period": SPAWN_MARK_LIFE}
	for kind in [ContentIds.CharacterIds.QUARTER, ContentIds.CharacterIds.HALF, ContentIds.CharacterIds.WHOLE, ContentIds.CharacterIds.EIGHTH]:
		var k: String = kind
		out["fx_decoy_" + k] = {"draw": func(ci, t): decoy(ci, k, t), "frames": 12, "period": TAU / 12.0}
	return out
