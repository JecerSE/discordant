class_name BossArt
## The static bodies of the five bosses, drawn in code. Each boss draws its body through
## Boss._boss_body_sprite (a sprite when "boss_<id>" is switched on in render_flags.tres,
## this code otherwise), and pipeline/render_placeholders.gd renders these same functions.
##
## A boss's body colours depend on its ink colour (normal, hit, stun, frozen), and those
## mixes aren't a plain multiply, so each boss has one sprite per ink colour:
## "boss_<id>_<tint>". What follows facing, the beat or time stays in the boss's code: eyes
## and pupils, the Conductor's baton and teleport blink, the Harp's vibrating strings, the
## Flute's breath and tilt, every aura and haze. No draw code depends on the boss's phase.
## Reads no game state and uses no randomness.

## Radius each boss sets in its _init (see the boss scripts).
const RADIUS := {"timpani": 62.0, "flute": 46.0, "harp": 52.0, "conductor": 34.0, "grand_staff": 48.0}


## The kettle and its skin (the face, rods and legs are drawn over it).
static func timpani_body(ci: CanvasItem, r: float, col: Color) -> void:
	var body := Pal.PERCUSSION.lerp(Pal.PAPER_DARK, 0.4)
	if col != Pal.INK:
		body = body.lerp(col, 0.4)
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		pts.append(Vector2(cos(a) * r * 1.1, -r * 0.1 + sin(a) * r * 0.95))
	ci.draw_colored_polygon(pts, body)
	pts.append(pts[0])
	ci.draw_polyline(pts, Pal.INK, 4.0, true)
	Glyph.fill_ellipse(ci, Vector2(0, -r * 0.1), r * 1.1, r * 0.3, 0.0, Pal.PAPER)
	Glyph.ring_ellipse(ci, Vector2(0, -r * 0.1), r * 1.1, r * 0.3, 0.0, Pal.INK, 4.0)


## Tension rods and legs, drawn over the face.
static func timpani_front(ci: CanvasItem, r: float) -> void:
	for i in 5:
		var x := -r * 0.9 + i * r * 0.45
		ci.draw_line(Vector2(x, -r * 0.05), Vector2(x * 0.9, r * 0.55), Color(Pal.INK, 0.6), 2.5)
	ci.draw_line(Vector2(-r * 0.6, r * 0.7), Vector2(-r * 0.8, r), Pal.INK, 4.0)
	ci.draw_line(Vector2(r * 0.6, r * 0.7), Vector2(r * 0.8, r), Pal.INK, 4.0)


## The flute, level (the boss tilts it), with the white of its eye but not the pupil.
static func flute_body(ci: CanvasItem, r: float, col: Color) -> void:
	var length := r * 2.6
	var body := Color(0.78, 0.78, 0.74) if col == Pal.INK else col
	ci.draw_rect(Rect2(-length, -r * 0.22, length * 2.0, r * 0.44), body)
	ci.draw_rect(Rect2(-length, -r * 0.22, length * 2.0, r * 0.44), Pal.INK, false, 3.0)
	for i in 6:
		var x := -length * 0.6 + i * length * 0.24
		ci.draw_circle(Vector2(x, 0), r * 0.08, Pal.INK)
	ci.draw_rect(Rect2(-length * 0.9, -r * 0.3, r * 0.3, r * 0.6), Pal.INK)
	ci.draw_circle(Vector2(length * 0.75, -r * 0.02), r * 0.2, Pal.PAPER)


## The harp's frame (its strings vibrate and stay in code).
static func harp_frame(ci: CanvasItem, r: float, col: Color) -> void:
	var gold := Pal.PODIUM if col == Pal.INK else col
	var h := r * 2.2
	var pts := PackedVector2Array()
	for i in 13:
		var k := i / 12.0
		pts.append(Vector2(-r + k * r * 2.0, -h * 0.5 - sin(k * PI) * r * 0.5 + k * r * 0.4))
	ci.draw_polyline(pts, gold, 7.0, true)
	ci.draw_line(Vector2(-r, -h * 0.5), Vector2(-r, h * 0.5), gold, 9.0, true)
	ci.draw_line(Vector2(-r, h * 0.5), Vector2(r, -h * 0.1), gold, 6.0, true)


## The tailcoat and whole-note head (the eye and baton stay in code).
static func conductor_body(ci: CanvasItem, r: float, col: Color) -> void:
	var ink := Pal.INK if col == Pal.INK else col
	var coat := PackedVector2Array([Vector2(-r * 0.55, -r * 0.4), Vector2(r * 0.55, -r * 0.4), Vector2(r * 0.7, r * 0.7),
		Vector2(r * 0.2, r * 0.5), Vector2(0, r), Vector2(-r * 0.2, r * 0.5), Vector2(-r * 0.7, r * 0.7)])
	ci.draw_colored_polygon(coat, ink)
	ci.draw_line(Vector2(0, -r * 0.4), Vector2(0, r * 0.4), Pal.PAPER, 2.0)
	Glyph.whole_head(ci, Vector2(0, -r * 0.95), r * 0.45, ink)


## The clef-eye and its five lines (the pupil, which looks where it faces, stays in code).
static func score_body(ci: CanvasItem, r: float, col: Color) -> void:
	var ink := Pal.GRAND if col == Pal.INK else col
	Glyph.treble_clef(ci, Vector2(0, r * 0.1), r * 0.9, ink, 5.0)
	Glyph.fill_ellipse(ci, Vector2(0, 0), r * 0.55, r * 0.35, 0.0, Pal.PAPER)
	Glyph.ring_ellipse(ci, Vector2(0, 0), r * 0.55, r * 0.35, 0.0, ink, 3.0)
	for i in 5:
		var y := -r * 1.2 + i * r * 0.18
		ci.draw_line(Vector2(-r * 1.4, y + r * 2.0), Vector2(r * 1.4, y + r * 2.0), Color(ink, 0.25), 1.5)


static func draw_boss(ci: CanvasItem, boss_id: String, col: Color) -> void:
	var r: float = RADIUS[boss_id]
	match boss_id:
		"timpani": timpani_body(ci, r, col)
		"flute": flute_body(ci, r, col)
		"harp": harp_frame(ci, r, col)
		"conductor": conductor_body(ci, r, col)
		"grand_staff": score_body(ci, r, col)


static func placeholders() -> Dictionary:
	var out := {}
	for boss_id in RADIUS:
		for tint in EnemyArt.TINTS:
			var b: String = boss_id
			var col := EnemyArt.tint_colour(tint)
			out["boss_%s_%s" % [b, tint]] = func(ci): draw_boss(ci, b, col)
	out["boss_timpani_front"] = func(ci): timpani_front(ci, RADIUS.timpani)
	return out
