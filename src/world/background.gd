extends Node2D
## The page itself: paper, the faint staff that runs under everything, bar lines, the clef at
## the start, watercolour once the room is freed, and the inked segments you stand on.

var room: Node
var _grain: PackedVector2Array
var _blobs: Array = []
var _hush_blobs: Array = []
var t := 0.0


func setup(r: Node, rng: RandomNumberGenerator) -> void:
	room = r
	z_index = -10
	_grain = PackedVector2Array()
	for i in int(room.width / 6.0):
		_grain.append(Vector2(rng.randf() * room.width, rng.randf() * room.floor_y))
	for i in int(room.width / 260.0) + 2:
		_blobs.append({"p": Vector2(rng.randf() * room.width, rng.randf_range(80, room.floor_y)), "r": rng.randf_range(90, 220)})
	for i in int(room.width / 300.0) + 2:
		_hush_blobs.append({"p": Vector2(rng.randf() * room.width, rng.randf_range(60, room.floor_y)), "r": rng.randf_range(60, 170), "ph": rng.randf() * TAU})


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var w: float = room.width
	var fy: float = room.floor_y
	var fam := Pal.family_color(room.family)
	draw_rect(Rect2(-400, -200, w + 800, 1200), Pal.PAPER)
	for g in _grain:
		draw_rect(Rect2(g, Vector2(1.5, 1.5)), Color(Pal.INK, 0.05))

	# Watercolour: the pillar's colour coming back.
	var wash: float = room.wash
	if wash > 0.01:
		for b in _blobs:
			draw_circle(b.p, b.r * (0.6 + 0.4 * wash), Color(fam, 0.07 * wash))
			draw_circle(b.p + Vector2(20, 10), b.r * 0.6 * (0.6 + 0.4 * wash), Color(fam, 0.06 * wash))
	# The Tacet: bruised violet smudges that drift while the room is hushed.
	var hush: float = room.hush_visual
	if hush > 0.01:
		for b in _hush_blobs:
			var p: Vector2 = b.p + Vector2(sin(t * 0.3 + b.ph) * 20.0, cos(t * 0.25 + b.ph) * 12.0)
			draw_circle(p, b.r, Color(Pal.HUSH, 0.05 * hush))
			draw_circle(p + Vector2(-b.r * 0.3, b.r * 0.2), b.r * 0.55, Color(Pal.HUSH, 0.04 * hush))

	# The staff beneath everything.
	for y in room.line_ys:
		draw_line(Vector2(0, y), Vector2(w, y), Color(Pal.INK, 0.10), 1.5)
	# Bar lines every measure.
	var bar_x := 640.0
	while bar_x < w - 100.0:
		draw_line(Vector2(bar_x, room.line_ys[4]), Vector2(bar_x, room.line_ys[0]), Color(Pal.INK, 0.07), 2.0)
		bar_x += 640.0
	# Clef and time signature at the head of the page.
	Glyph.clef(self, room.family, Vector2(70, room.line_ys[1] + 20), 70.0, Color(Pal.INK, 0.12), 5.0)
	var f := Pal.serif_bold()
	draw_string(f, Vector2(150, room.line_ys[2] + 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, Color(Pal.INK, 0.08))
	draw_string(f, Vector2(150, room.line_ys[0] + 10), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 96, Color(Pal.INK, 0.08))

	# Features under the ink.
	for ft in room.features:
		_draw_feature(ft)

	# The inked segments you can stand on.
	for s in room.segments:
		var col := Pal.INK if not s.get("hazard", false) else Pal.BLOOD
		draw_line(Vector2(s.x0, s.y), Vector2(s.x1, s.y), col, 4.0, true)
		draw_line(Vector2(s.x0, s.y - 6), Vector2(s.x0, s.y + 6), Color(col, 0.5), 2.0)
		draw_line(Vector2(s.x1, s.y - 6), Vector2(s.x1, s.y + 6), Color(col, 0.5), 2.0)

	# The floor: the bottom margin of the page.
	draw_rect(Rect2(-400, fy, w + 800, 400), Pal.PAPER_DARK)
	draw_line(Vector2(0, fy), Vector2(w, fy), Pal.INK, 5.0)
	for i in int(w / 48.0):
		var x := i * 48.0 + 12.0
		draw_line(Vector2(x, fy + 6), Vector2(x - 10, fy + 20), Color(Pal.INK, 0.15), 1.5)

	# The exit: a final double bar, open or closed.
	if room.has_exit:
		var ex: float = w - 40.0
		var top: float = room.line_ys[4]
		var open: bool = room.exit_open
		var a := 1.0 if open else 0.3
		draw_line(Vector2(ex - 14, top), Vector2(ex - 14, fy), Color(Pal.INK, a), 3.0)
		draw_line(Vector2(ex, top), Vector2(ex, fy), Color(Pal.INK, a), 10.0)
		if open:
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_rect(Rect2(ex - 70, fy - 170, 60, 170), Color(fam if room.family != "ledger" else Pal.GOLD, 0.10 + 0.08 * pulse))
			var arrow := PackedVector2Array([Vector2(ex - 58, fy - 90), Vector2(ex - 34, fy - 76), Vector2(ex - 58, fy - 62)])
			draw_polyline(arrow, Color(Pal.INK, 0.4 + 0.4 * pulse), 3.0, true)
		else:
			for i in 4:
				var y := top + 40.0 + i * 120.0
				draw_line(Vector2(ex - 30, y), Vector2(ex + 16, y + 30), Color(Pal.HUSH, 0.5), 3.0)
	# Page edges.
	draw_line(Vector2(0, -200), Vector2(0, fy), Color(Pal.INK, 0.3), 2.0)
	draw_line(Vector2(w, -200), Vector2(w, fy), Color(Pal.INK, 0.3), 2.0)


func _draw_feature(ft: Dictionary) -> void:
	match ft.kind:
		"drum":
			var p: Vector2 = ft.pos
			var sq: float = ft.get("squash", 0.0)
			var rect := Rect2(p + Vector2(-38, -30 + sq * 8.0), Vector2(76, 30 - sq * 8.0))
			draw_rect(rect, Pal.PERCUSSION.lerp(Pal.PAPER, 0.35))
			draw_rect(rect, Pal.INK, false, 3.0)
			Glyph.ring_ellipse(self, p + Vector2(0, -30 + sq * 8.0), 38.0, 7.0, 0.0, Pal.INK, 3.0)
			for i in 4:
				var x := -30.0 + i * 20.0
				draw_line(p + Vector2(x, -26 + sq * 8.0), p + Vector2(x + 10, -2), Color(Pal.INK, 0.5), 2.0)
		"updraft":
			var x: float = ft.pos.x
			var wdt: float = ft.w
			draw_rect(Rect2(x - wdt * 0.5, 60, wdt, room.floor_y - 60), Color(Pal.WIND, 0.07))
			for i in 7:
				var yy: float = room.floor_y - fmod(t * 220.0 + i * 90.0, room.floor_y - 60.0)
				var xx := x - wdt * 0.35 + (i % 3) * wdt * 0.35
				draw_line(Vector2(xx, yy), Vector2(xx, yy - 26), Color(Pal.WIND, 0.45), 2.0, true)
			draw_arc(Vector2(x, room.floor_y - 4), wdt * 0.5, PI, TAU, 16, Color(Pal.WIND, 0.5), 2.0)
		"harmonic":
			var p2: Vector2 = ft.pos
			var cd: float = ft.get("cd", 0.0)
			var a := 0.9 if cd <= 0.0 else 0.35
			draw_circle(p2, 16.0, Color(Pal.STRING, 0.15 * a))
			draw_arc(p2, 16.0 + sin(t * 3.0) * 2.0, 0, TAU, 20, Color(Pal.STRING, a), 2.5, true)
			draw_line(p2 + Vector2(0, -16), p2 + Vector2(0, -40), Color(Pal.STRING, a * 0.6), 1.5)
			draw_circle(p2, 4.0, Color(Pal.STRING, a))
		"string":
			var x2: float = ft.pos.x
			var vib: float = ft.get("vib", 0.0)
			var pts := PackedVector2Array()
			for i in 21:
				var yy2 := lerpf(ft.top, room.floor_y, i / 20.0)
				pts.append(Vector2(x2 + sin(i * 0.9 + t * 50.0) * vib * sin(PI * i / 20.0), yy2))
			draw_polyline(pts, Color(Pal.STRING, 0.55), 2.0, true)
