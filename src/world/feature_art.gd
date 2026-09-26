class_name FeatureArt
## How the room features look: drum pads (a sprite), updraft columns, harmonic nodes and
## the vibrating strings. Called from the room background's _draw().


static func draw(ci: CanvasItem, room: Node, ft: Dictionary, t: float) -> void:
	match ft.kind:
		"drum":
			_drum(ci, ft)
		"updraft":
			_updraft(ci, room, ft, t)
		"harmonic":
			_harmonic(ci, ft, t)
		"string":
			_string(ci, room, ft, t)


static func _drum(ci: CanvasItem, ft: Dictionary) -> void:
	var sheet := ArtLibrary.sheet("prop_drum_pad")
	var sq: float = ft.get("squash", 0.0)
	var squash := Vector2(1.0 + sq * 0.15, 1.0 - sq * 0.3)
	ArtLibrary.draw_frame(ci, sheet, 1 if sq > 0.3 else 0, ft.pos, squash)


static func _updraft(ci: CanvasItem, room: Node, ft: Dictionary, t: float) -> void:
	var x: float = ft.pos.x
	var wdt: float = ft.w
	var top := 60.0
	var fy: float = room.floor_y
	ci.draw_rect(Rect2(x - wdt * 0.5, top, wdt, fy - top), Color(Pal.WIND, 0.07))
	# Square pixel streaks rising, snapped to a 3 px grid.
	for i in 7:
		var yy := snappedf(fy - fmod(t * 220.0 + i * 90.0, fy - top), 3.0)
		var xx := snappedf(x - wdt * 0.35 + (i % 3) * wdt * 0.35, 3.0)
		ci.draw_rect(Rect2(xx, yy - 24.0, 3.0, 24.0), Color(Pal.WIND, 0.5))
	ci.draw_arc(Vector2(x, fy - 4), wdt * 0.5, PI, TAU, 16, Color(Pal.WIND, 0.5), 3.0)


static func _harmonic(ci: CanvasItem, ft: Dictionary, t: float) -> void:
	var p: Vector2 = ft.pos
	var a := 0.9 if ft.get("cd", 0.0) <= 0.0 else 0.35
	var r := 15.0 + snappedf(sin(t * 3.0) * 3.0, 3.0)
	ci.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color(Pal.STRING, 0.15 * a))
	ci.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color(Pal.STRING, a), false, 3.0)
	ci.draw_rect(Rect2(p + Vector2(-1.5, -40), Vector2(3, 40 - r)), Color(Pal.STRING, a * 0.6))
	ci.draw_rect(Rect2(p - Vector2(4.5, 4.5), Vector2(9, 9)), Color(Pal.STRING, a))


static func _string(ci: CanvasItem, room: Node, ft: Dictionary, t: float) -> void:
	var x: float = ft.pos.x
	var vib: float = ft.get("vib", 0.0)
	var steps := 24
	for i in steps:
		var y0 := lerpf(ft.top, room.floor_y, float(i) / steps)
		var y1 := lerpf(ft.top, room.floor_y, float(i + 1) / steps)
		var dx := snappedf(sin(i * 0.9 + t * 50.0) * vib * sin(PI * i / steps), 3.0)
		ci.draw_rect(Rect2(x + dx - 1.5, y0, 3.0, y1 - y0), Color(Pal.STRING, 0.6))
