class_name PropArt
## The static parts of props, drawn in code. Interactable draws them through RenderAdapter
## (a sprite when its key is switched on in content/art/render_flags.tres, this code
## otherwise), and pipeline/render_placeholders.gd renders these same functions into the
## placeholder PNGs, so the two paths can't drift apart. Moving parts (a shop's floating
## item and price, a statue's note and name, glows) stay in Interactable.

const FAMILIES := ["ledger", "percussion", "wind", "string", "podium", "grand"]


static func key_chest(family: String, used: bool) -> String:
	return "prop_chest_%s%s" % [family, "_open" if used else ""]


static func chest(ci: CanvasItem, family: String, used: bool) -> void:
	Glyph.chest(ci, Vector2(0, -18), 26.0, Pal.INK, Pal.family_color(family), used)


static func shop_stand(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(-26, -10, 52, 10), Pal.INK)
	ci.draw_line(Vector2(-18, -10), Vector2(-14, -40), Pal.INK, 3.0)
	ci.draw_line(Vector2(18, -10), Vector2(14, -40), Pal.INK, 3.0)
	ci.draw_line(Vector2(-22, -40), Vector2(22, -40), Pal.INK, 3.0)


static func bench(ci: CanvasItem, used: bool) -> void:
	ci.draw_line(Vector2(-50, 0), Vector2(-50, -30), Pal.INK, 4.0)
	ci.draw_line(Vector2(50, 0), Vector2(50, -30), Pal.INK, 4.0)
	ci.draw_line(Vector2(-60, -30), Vector2(60, -30), Pal.INK, 6.0)
	Glyph.fermata(ci, Vector2(0, -60), 26.0, Pal.INK if not used else Pal.INK_SOFT)


static func statue_base(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(-34, -14, 68, 14), Pal.INK_SOFT)


static func sign_board(ci: CanvasItem) -> void:
	ci.draw_line(Vector2(0, 0), Vector2(0, -40), Pal.INK, 4.0)
	ci.draw_rect(Rect2(-40, -80, 80, 44), Pal.PAPER_DARK)
	ci.draw_rect(Rect2(-40, -80, 80, 44), Pal.INK, false, 2.5)
	for i in 3:
		ci.draw_line(Vector2(-30, -70 + i * 11), Vector2(30 - i * 12, -70 + i * 11), Pal.INK_SOFT, 2.0)


## Every placeholder key and how to draw it, for the generator.
static func placeholders() -> Dictionary:
	var out := {
		"prop_sign": func(ci): sign_board(ci),
		"prop_bench": func(ci): bench(ci, false),
		"prop_bench_used": func(ci): bench(ci, true),
		"prop_shop_stand": func(ci): shop_stand(ci),
		"prop_statue_base": func(ci): statue_base(ci),
	}
	for fam in FAMILIES:
		for used in [false, true]:
			var f: String = fam
			var u: bool = used
			out[key_chest(f, u)] = func(ci): chest(ci, f, u)
	return out
