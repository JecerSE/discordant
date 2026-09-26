class_name HudPowerIcons
## Drawn icon for each power family, shared by the power bar and menus.


static func draw(ci: CanvasItem, family: String, c: Vector2, col: Color, scale := 1.0) -> void:
	var s := scale
	match family:
		"percussion":
			ci.draw_rect(Rect2(c + Vector2(-14, -4) * s, Vector2(28, 14) * s), Color(col, 0.35))
			ci.draw_rect(Rect2(c + Vector2(-14, -4) * s, Vector2(28, 14) * s), col, false, 2.0)
			ci.draw_line(c + Vector2(-8, -14) * s, c + Vector2(4, -4) * s, col, 2.5)
		"wind":
			for i in 3:
				ci.draw_arc(c + Vector2(-6 + i * 5, 0) * s, (10.0 - i * 2.0) * s, -0.9, 0.9, 10, col, 2.5, true)
		"string":
			for i in 3:
				ci.draw_line(c + Vector2(-8 + i * 8, -14) * s, c + Vector2(-8 + i * 8, 14) * s, col, 1.5)
			ci.draw_arc(c, 12.0 * s, 0, TAU, 20, col, 2.0, true)
		_:
			Glyph.fermata(ci, c + Vector2(0, 6) * s, 12.0 * s, col)
