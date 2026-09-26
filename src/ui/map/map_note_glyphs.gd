class_name MapNoteGlyphs
## One engraved note per room type, so the map reads like a score (issue #24).
##   fight: quarter · elite: half + accent · shop: sharp + quarter · treasure: whole
##   teacher: eighth · rest: half under a fermata · boss: breve

const HEAD := 9.0
const STEM := 34.0


## `stem_up`: stems point up for notes on the lower half of the staff.
static func draw(ci: CanvasItem, room_type: String, at: Vector2, col: Color, stem_up: bool) -> void:
	var dir := -1.0 if stem_up else 1.0
	var stem_x := HEAD * 1.1 if stem_up else -HEAD * 1.1
	match room_type:
		"combat":
			Glyph.head(ci, at, HEAD, true, col)
			_stem(ci, at, stem_x, dir, col)
		"elite":
			Glyph.head(ci, at, HEAD, false, col)
			_stem(ci, at, stem_x, dir, col)
			# Accents sit on the side of the head away from the stem.
			var accent_y := HEAD + 18.0 if stem_up else -(HEAD + 18.0)
			_accent(ci, at + Vector2(0, accent_y), col)
		"shop":
			Glyph.sharp(ci, at + Vector2(-HEAD * 2.6, 0), HEAD * 0.8, col)
			Glyph.head(ci, at, HEAD, true, col)
			_stem(ci, at, stem_x, dir, col)
		"chest":
			Glyph.whole_head(ci, at, HEAD, col)
		"teach":
			Glyph.head(ci, at, HEAD, true, col)
			var top := _stem(ci, at, stem_x, dir, col)
			_flag(ci, top, dir, col)
		"rest":
			Glyph.head(ci, at, HEAD, false, col)
			_stem(ci, at, stem_x, dir, col)
			Glyph.fermata(ci, at + Vector2(0, -STEM - 18.0 if stem_up else -HEAD - 18.0), HEAD * 1.2, col)
		"boss":
			Glyph.whole_head(ci, at, HEAD * 1.3, col)
			for side in [-1.0, 1.0]:
				var x: float = side * HEAD * 2.1
				ci.draw_line(at + Vector2(x, -HEAD * 1.2), at + Vector2(x, HEAD * 1.2), col, 2.5)
				ci.draw_line(at + Vector2(x + side * 4.0, -HEAD * 1.2), at + Vector2(x + side * 4.0, HEAD * 1.2), col, 2.5)
		_:
			Glyph.head(ci, at, HEAD, true, col)


static func _stem(ci: CanvasItem, at: Vector2, stem_x: float, dir: float, col: Color) -> Vector2:
	var base := at + Vector2(stem_x, -HEAD * 0.2 * dir)
	var top := base + Vector2(0, dir * STEM)
	ci.draw_line(base, top, col, 2.2, true)
	return top


static func _flag(ci: CanvasItem, top: Vector2, dir: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var k := i / 7.0
		pts.append(top + Vector2(sin(k * 2.2) * 11.0, -dir * k * 20.0))
	ci.draw_polyline(pts, col, 2.5, true)


static func _accent(ci: CanvasItem, at: Vector2, col: Color) -> void:
	ci.draw_polyline(PackedVector2Array([at + Vector2(-7, -4), at + Vector2(7, 0), at + Vector2(-7, 4)]), col, 2.2, true)
