class_name UI
## Drawing helpers shared by every screen: text, panels, cards.


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, bold := false) -> void:
	var f := Pal.serif_bold() if bold else Pal.serif()
	var p := pos
	if align == HORIZONTAL_ALIGNMENT_CENTER and width < 0.0:
		p.x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT and width < 0.0:
		p.x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if width > 0.0:
		ci.draw_string(f, pos, s, align, width, size, col)
	else:
		ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func outlined(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, outline := Pal.PAPER, align := HORIZONTAL_ALIGNMENT_CENTER, bold := true) -> void:
	var f := Pal.serif_bold() if bold else Pal.serif()
	var p := pos
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		p.x -= w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		p.x -= w
	ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, outline)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func wrapped(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float, max_lines := -1, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_multiline_string(Pal.serif(), pos, s, align, width, size, max_lines, col)


static func text_width(s: String, size: int, bold := false) -> float:
	var f := Pal.serif_bold() if bold else Pal.serif()
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## A sheet of paper with a soft shadow and a hairline edge.
static func panel(ci: CanvasItem, r: Rect2, accent := Color(0, 0, 0, 0)) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 6), r.size), Color(0, 0, 0, 0.12))
	ci.draw_rect(r, Pal.PAPER)
	ci.draw_rect(r, Color(Pal.INK, 0.25), false, 1.5)
	if accent.a > 0.0:
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), accent)


static func dim(ci: CanvasItem, size: Vector2, a := 0.45) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.INK, a))


static func kind_label(id: String) -> String:
	if Content.POWERS.has(id):
		var fam: String = Content.POWERS[id].family
		return ("Rest power" if fam == "margin" else fam.capitalize() + " power")
	if Content.RUNES.has(id):
		var d: Dictionary = Content.RUNES[id]
		match d.kind:
			"family": return d.family.capitalize() + " rune"
			"permanent": return "Permanent rune"
			"margin": return "Margin rune"
			"pause": return "Pause rune"
		return "Rune"
	if Content.RELICS.has(id):
		return "Champion memorabilia" if Content.RELICS[id].get("champion", false) else "Relic"
	if id == "heal":
		return "Consumable"
	return ""


static func item_name(id: String) -> String:
	if id == "heal":
		return "Staccato Dot"
	return Content.item(id).name


static func item_desc(id: String) -> String:
	if id == "heal":
		return "Heal 30 HP."
	var d := Content.item(id)
	var s: String = d.get("desc", "")
	if Content.POWERS.has(id):
		s += "\nCooldown %.1fs." % float(d.cd)
	var reason := ItemRequirements.missing_reason(id) if Game.has_run() else ""
	if reason != "":
		s += "\n(Does nothing yet: %s.)" % reason
	return s
