class_name Glyph
## Engraving by hand. Every note, rest, clef and accidental in the game is drawn by these
## functions onto whatever CanvasItem asks, so the whole look is one consistent ink.


static func ellipse(center: Vector2, rx: float, ry: float, rot := 0.0, n := 22) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := cos(rot)
	var s := sin(rot)
	for i in n:
		var a := TAU * i / n
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		pts.append(center + Vector2(p.x * c - p.y * s, p.x * s + p.y * c))
	return pts


static func fill_ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, rot: float, color: Color) -> void:
	ci.draw_colored_polygon(ellipse(center, rx, ry, rot), color)


static func ring_ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, rot: float, color: Color, width: float) -> void:
	var pts := ellipse(center, rx, ry, rot, 26)
	pts.append(pts[0])
	ci.draw_polyline(pts, color, width, true)


## A note head. Engraved heads tilt up to the right.
static func head(ci: CanvasItem, pos: Vector2, size: float, filled: bool, color: Color, paper := Pal.PAPER) -> void:
	var rx := size * 1.25
	var ry := size * 0.9
	if filled:
		fill_ellipse(ci, pos, rx, ry, -0.4, color)
	else:
		fill_ellipse(ci, pos, rx, ry, -0.4, color)
		# The hollow of a half/whole note is a thinner ellipse tilted the other way.
		fill_ellipse(ci, pos, rx * 0.72, ry * 0.42, 0.55, paper)


## The whole note: wider, with a hollow tilted against the grain.
static func whole_head(ci: CanvasItem, pos: Vector2, size: float, color: Color, paper := Pal.PAPER) -> void:
	fill_ellipse(ci, pos, size * 1.45, size, 0.0, color)
	fill_ellipse(ci, pos, size * 0.62, size * 0.8, 0.95, paper)


## A player-character note. `stem_angle` sways the stem; `squash` flattens on landing.
## Parts of a note, for drawing some of them (the head can come from a sprite).
const NOTE_STEM := 1
const NOTE_HEAD := 2
const NOTE_EYES := 4


static func note(ci: CanvasItem, kind: String, pos: Vector2, facing: float, size: float, color: Color,
		stem_angle := 0.0, squash := 1.0, paper := Pal.PAPER, blink := false, parts := 7) -> void:
	var stem_on := parts & NOTE_STEM != 0
	var head_on := parts & NOTE_HEAD != 0
	var sz := size
	var hp := pos
	var stem_len := size * 3.4
	var sx := facing
	var head_offset := Vector2(size * 1.05 * sx, -size * 0.25)
	match kind:
		ContentIds.CharacterIds.WHOLE:
			if head_on:
				whole_head(ci, hp, sz * 1.1, color, paper)
		ContentIds.CharacterIds.HALF:
			if stem_on:
				_stem(ci, hp + head_offset, stem_len, stem_angle * sx, color, size)
			if head_on:
				head(ci, hp, sz, false, color, paper)
		ContentIds.CharacterIds.EIGHTH:
			if stem_on:
				var top := _stem(ci, hp + head_offset, stem_len, stem_angle * sx, color, size)
				_flag(ci, top, sx, size, color, 1)
			if head_on:
				head(ci, hp, sz, true, color)
		_:
			if stem_on:
				_stem(ci, hp + head_offset, stem_len, stem_angle * sx, color, size)
			if head_on:
				head(ci, hp, sz, true, color)
	if parts & NOTE_EYES == 0:
		return
	# Eyes — paper on a filled head, ink on a hollow one, perched on the hollow's rim.
	var eye_col := paper if (kind == ContentIds.CharacterIds.QUARTER or kind == ContentIds.CharacterIds.EIGHTH) else color
	var ex := size * 0.45 * sx
	var ey := -size * 0.15 if (kind == ContentIds.CharacterIds.QUARTER or kind == ContentIds.CharacterIds.EIGHTH) else -size * 0.55
	if kind == ContentIds.CharacterIds.WHOLE:
		ey = -size * 0.55
		ex = size * 0.7 * sx
	var eh := size * 0.08 if blink else size * 0.22 * squash
	for off in [Vector2(-size * 0.28, 0), Vector2(size * 0.28, 0)]:
		fill_ellipse(ci, hp + Vector2(ex, ey) + off, size * 0.12, eh, 0.0, eye_col)


static func _stem(ci: CanvasItem, base: Vector2, length: float, angle: float, color: Color, size: float) -> Vector2:
	var top := base + Vector2(sin(angle), -cos(angle)) * length
	ci.draw_line(base, top, color, maxf(2.0, size * 0.22), true)
	return top


static func _flag(ci: CanvasItem, top: Vector2, sx: float, size: float, color: Color, count: int) -> void:
	for f in count:
		var start := top + Vector2(0, f * size * 0.9)
		var pts := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			pts.append(start + Vector2(sx * size * (0.2 + 1.3 * sin(t * 2.2)) , size * 2.4 * t))
		ci.draw_polyline(pts, color, maxf(2.0, size * 0.32), true)


# --- rests: the Tacet's soldiers --------------------------------------------------------------

## `layers`: REST_BODY (the rest in `color`), REST_ACCENT (the parts in `accent`: the tether
## ring, the gust lines), or both (the default). Sprites render the layers separately.
const REST_BODY := 1
const REST_ACCENT := 2


static func rest(ci: CanvasItem, kind: String, pos: Vector2, s: float, color: Color, t := 0.0, accent := Color(0, 0, 0, 0), layers := 3) -> void:
	var body := layers & REST_BODY != 0
	var acc := layers & REST_ACCENT != 0
	match kind:
		"quarter_rest", "tether_rest":
			var pts := PackedVector2Array([
				Vector2(-0.35, -1.35), Vector2(0.45, -0.45), Vector2(-0.25, 0.15),
				Vector2(0.45, 0.85), Vector2(-0.3, 0.7), Vector2(0.2, 1.35)])
			var out := PackedVector2Array()
			for p in pts:
				out.append(pos + p * s + Vector2(sin(t * 6.0 + p.y * 2.0) * s * 0.06, 0))
			if body:
				ci.draw_polyline(out, color, s * 0.42, true)
			if kind == "tether_rest" and acc:
				ci.draw_arc(pos + Vector2(0, -s * 1.5), s * 0.45, 0, TAU, 16, accent if accent.a > 0 else color, s * 0.14, true)
		"eighth_rest", "sixteenth_rest", "gust_rest":
			var dots := 0 if not body else (2 if kind == "sixteenth_rest" else 1)
			if body:
				ci.draw_line(pos + Vector2(s * 0.55, -s * 1.1), pos + Vector2(-s * 0.2, s * 1.2), color, s * 0.26, true)
			for d in dots:
				var dp := pos + Vector2(-s * 0.45 + d * s * 0.3, -s * 0.85 + d * s * 0.75)
				ci.draw_circle(dp, s * 0.36, color)
				var arc := PackedVector2Array()
				for i in 7:
					var k := i / 6.0
					arc.append(dp + Vector2(s * 0.2 + k * s * 0.8, s * 0.25 - sin(k * PI) * s * 0.35))
				ci.draw_polyline(arc, color, s * 0.16, true)
			if kind == "gust_rest" and acc:
				for w in 3:
					var y := pos.y + (w - 1) * s * 0.7
					var off := fmod(t * 120.0 + w * 20.0, s * 1.6)
					ci.draw_line(Vector2(pos.x - s * 1.8 + off, y), Vector2(pos.x - s * 1.1 + off, y), accent if accent.a > 0 else color, 2.0, true)
		_ when not body:
			pass
		"whole_rest":
			ci.draw_line(pos + Vector2(-s * 1.4, -s * 0.5), pos + Vector2(s * 1.4, -s * 0.5), color, 3.0, true)
			ci.draw_rect(Rect2(pos + Vector2(-s * 0.9, -s * 0.5), Vector2(s * 1.8, s * 0.9)), color)
		"half_rest":
			ci.draw_rect(Rect2(pos + Vector2(-s * 0.9, -s * 0.4), Vector2(s * 1.8, s * 0.9)), color)
			ci.draw_line(pos + Vector2(-s * 1.4, s * 0.5), pos + Vector2(s * 1.4, s * 0.5), color, 3.0, true)
		"snare_rest":
			# A quarter rest wearing a drum.
			ci.draw_rect(Rect2(pos + Vector2(-s * 0.9, s * 0.1), Vector2(s * 1.8, s * 0.9)), color, false, 3.0)
			for i in 4:
				var x := -s * 0.8 + i * s * 0.53
				ci.draw_line(pos + Vector2(x, s * 0.1), pos + Vector2(x + s * 0.26, s * 1.0), color, 2.0, true)
			var z := PackedVector2Array([pos + Vector2(-s * 0.3, -s * 1.3), pos + Vector2(s * 0.35, -s * 0.6), pos + Vector2(-s * 0.2, -s * 0.2), pos + Vector2(s * 0.2, s * 0.1)])
			ci.draw_polyline(z, color, s * 0.35, true)
		"echo_rest":
			ci.draw_circle(pos, s * 0.55, color)
			for r in 3:
				var rr := s * (0.9 + r * 0.45 + fmod(t, 1.0) * 0.45)
				ci.draw_arc(pos, rr, -0.7, 0.7, 10, Color(color, 0.7 - r * 0.2), 2.5, true)
				ci.draw_arc(pos, rr, PI - 0.7, PI + 0.7, 10, Color(color, 0.7 - r * 0.2), 2.5, true)
		_:
			ci.draw_circle(pos, s, color)


# --- signs and marks ---------------------------------------------------------------------------

static func sharp(ci: CanvasItem, pos: Vector2, s: float, color: Color) -> void:
	var w := maxf(1.5, s * 0.14)
	ci.draw_line(pos + Vector2(-s * 0.25, -s * 0.95), pos + Vector2(-s * 0.25, s * 1.05), color, w, true)
	ci.draw_line(pos + Vector2(s * 0.25, -s * 1.05), pos + Vector2(s * 0.25, s * 0.95), color, w, true)
	ci.draw_line(pos + Vector2(-s * 0.55, -s * 0.2), pos + Vector2(s * 0.55, -s * 0.45), color, w * 2.2, true)
	ci.draw_line(pos + Vector2(-s * 0.55, s * 0.45), pos + Vector2(s * 0.55, s * 0.2), color, w * 2.2, true)


static func flat(ci: CanvasItem, pos: Vector2, s: float, color: Color) -> void:
	ci.draw_line(pos + Vector2(-s * 0.3, -s * 1.2), pos + Vector2(-s * 0.3, s * 0.6), color, maxf(1.5, s * 0.14), true)
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(pos + Vector2(-s * 0.3 + sin(t * PI) * s * 0.7, s * 0.6 - t * s * 0.9 + sin(t * PI) * 0.0))
	ci.draw_polyline(pts, color, maxf(1.5, s * 0.2), true)


static func fermata(ci: CanvasItem, pos: Vector2, s: float, color: Color) -> void:
	ci.draw_arc(pos, s, PI, TAU, 18, color, maxf(2.0, s * 0.2), true)
	ci.draw_circle(pos + Vector2(0, -s * 0.2), s * 0.2, color)


static func treble_clef(ci: CanvasItem, pos: Vector2, s: float, color: Color, width := 3.0) -> void:
	var pts := PackedVector2Array()
	# The spiral around the G line, then up into the loop, then down the spine.
	for i in 40:
		var t := i / 39.0
		var a := t * TAU * 1.25 + PI * 0.5
		var r := s * (0.15 + 0.5 * t)
		pts.append(pos + Vector2(cos(a) * r, sin(a) * r * 1.1))
	var last := pts[pts.size() - 1]
	pts.append(last + Vector2(s * 0.3, -s * 0.9))
	pts.append(pos + Vector2(s * 0.35, -s * 2.0))
	pts.append(pos + Vector2(s * 0.05, -s * 2.3))
	pts.append(pos + Vector2(-s * 0.2, -s * 1.9))
	pts.append(pos + Vector2(s * 0.1, -s * 0.8))
	pts.append(pos + Vector2(s * 0.2, s * 0.6))
	pts.append(pos + Vector2(s * 0.12, s * 1.35))
	pts.append(pos + Vector2(-s * 0.2, s * 1.45))
	ci.draw_polyline(pts, color, width, true)
	ci.draw_circle(pos + Vector2(-s * 0.25, s * 1.3), s * 0.16, color)


static func bass_clef(ci: CanvasItem, pos: Vector2, s: float, color: Color, width := 3.0) -> void:
	var pts := PackedVector2Array()
	for i in 22:
		var t := i / 21.0
		var a := -PI * 0.95 + t * PI * 1.35
		pts.append(pos + Vector2(cos(a) * s * 0.7, sin(a) * s * 0.75))
	pts.append(pos + Vector2(s * 0.1, s * 1.2))
	pts.append(pos + Vector2(-s * 0.7, s * 1.7))
	ci.draw_polyline(pts, color, width, true)
	ci.draw_circle(pos + Vector2(-s * 0.55, -s * 0.2), s * 0.2, color)
	ci.draw_circle(pos + Vector2(s * 1.0, -s * 0.4), s * 0.12, color)
	ci.draw_circle(pos + Vector2(s * 1.0, s * 0.3), s * 0.12, color)


static func alto_clef(ci: CanvasItem, pos: Vector2, s: float, color: Color, width := 3.0) -> void:
	ci.draw_line(pos + Vector2(-s * 0.8, -s * 1.5), pos + Vector2(-s * 0.8, s * 1.5), color, width * 2.0, true)
	ci.draw_line(pos + Vector2(-s * 0.45, -s * 1.5), pos + Vector2(-s * 0.45, s * 1.5), color, width * 0.8, true)
	for sy in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 12:
			var t := i / 11.0
			var a := -PI * 0.5 + t * PI
			pts.append(pos + Vector2(s * 0.3 + cos(a) * s * 0.45, sy * s * 0.75 + sin(a) * s * 0.7 * sy * -1.0))
		ci.draw_polyline(pts, color, width, true)
	ci.draw_line(pos + Vector2(-s * 0.45, 0), pos + Vector2(s * 0.1, 0), color, width, true)


static func clef(ci: CanvasItem, family: String, pos: Vector2, s: float, color: Color, width := 3.0) -> void:
	match family:
		"percussion": bass_clef(ci, pos, s, color, width)
		"string": alto_clef(ci, pos, s, color, width)
		_: treble_clef(ci, pos, s, color, width)


## A small chest drawn as a folded page with a wax seal.
static func chest(ci: CanvasItem, pos: Vector2, s: float, color: Color, seal: Color, open := false) -> void:
	var body := Rect2(pos + Vector2(-s, -s * 0.5), Vector2(s * 2, s * 1.1))
	ci.draw_rect(body, Pal.PAPER_DARK)
	ci.draw_rect(body, color, false, 2.5)
	if open:
		ci.draw_line(pos + Vector2(-s, -s * 0.5), pos + Vector2(-s * 0.7, -s * 1.3), color, 2.5, true)
		ci.draw_line(pos + Vector2(-s * 0.7, -s * 1.3), pos + Vector2(s * 1.2, -s * 1.1), color, 2.5, true)
	else:
		var lid := PackedVector2Array([pos + Vector2(-s, -s * 0.5), pos + Vector2(0, -s * 1.0), pos + Vector2(s, -s * 0.5)])
		ci.draw_polyline(lid, color, 2.5, true)
		ci.draw_circle(pos + Vector2(0, -s * 0.35), s * 0.3, seal)


## Map-node icon for each room type.
static func node_icon(ci: CanvasItem, type: String, pos: Vector2, s: float, color: Color, family: String) -> void:
	var fam := Pal.family_color(family)
	match type:
		"combat":
			rest(ci, "quarter_rest", pos, s * 0.55, color)
		"elite":
			rest(ci, "half_rest", pos + Vector2(0, s * 0.2), s * 0.6, color)
			var crown := PackedVector2Array([pos + Vector2(-s * 0.6, -s * 0.5), pos + Vector2(-s * 0.4, -s * 0.95),
				pos + Vector2(-s * 0.1, -s * 0.6), pos + Vector2(0, -s * 1.05), pos + Vector2(s * 0.1, -s * 0.6),
				pos + Vector2(s * 0.4, -s * 0.95), pos + Vector2(s * 0.6, -s * 0.5)])
			ci.draw_polyline(crown, fam, 2.5, true)
		"shop":
			sharp(ci, pos, s * 0.75, color)
		"chest":
			chest(ci, pos + Vector2(0, s * 0.2), s * 0.6, color, fam)
		"teach":
			fill_ellipse(ci, pos, s * 0.7, s * 0.42, 0.0, color)
			fill_ellipse(ci, pos, s * 0.3, s * 0.3, 0.0, Pal.PAPER)
			ci.draw_circle(pos, s * 0.14, color)
		"rest":
			fermata(ci, pos + Vector2(0, s * 0.35), s * 0.7, color)
		"boss":
			clef(ci, family, pos, s * 0.6, color, 3.0)
		_:
			ci.draw_circle(pos, s * 0.4, color)
