extends Overlay
## Pick one of several items, laid out as cards. Mouse, keys and controller.

var title := ""
var subtitle := ""
var ids: Array = []
var prices := {}
var allow_skip := true
var callback: Callable
var sel := 0
var _t := 0.0
var _rects: Array = []


func handle_input() -> void:
	var n := ids.size() + (1 if allow_skip else 0)
	if left() or up():
		sel = (sel - 1 + n) % n
		Synth.sfx_play("tick", -12.0)
	elif right() or down():
		sel = (sel + 1) % n
		Synth.sfx_play("tick", -12.0)
	elif confirm():
		_choose(sel)
	elif cancel() and allow_skip:
		_choose(ids.size())


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseMotion:
		for i in _rects.size():
			if _rects[i].has_point(event.position):
				sel = i
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in _rects.size():
			if _rects[i].has_point(event.position):
				_choose(i)
				return


func _choose(i: int) -> void:
	var id := ""
	if i < ids.size():
		id = ids[i]
	Synth.sfx_play("chime" if id != "" else "tick", -8.0)
	var cb := callback
	queue_free()
	if cb.is_valid():
		cb.call(id)


func _draw() -> void:
	_t += get_process_delta_time()
	UI.dim(self, size, 0.4)
	var cx := size.x * 0.5
	UI.outlined(self, Vector2(cx, 120), title, 38, Pal.INK, Pal.PAPER)
	if subtitle != "":
		UI.outlined(self, Vector2(cx, 156), subtitle, 18, Pal.INK_SOFT, Pal.PAPER, HORIZONTAL_ALIGNMENT_CENTER, false)
	var n := ids.size()
	var cw := 280.0
	var ch := 330.0
	var gap := 28.0
	var total := n * cw + (n - 1) * gap
	var x0 := cx - total * 0.5
	_rects.clear()
	for i in n:
		var id: String = ids[i]
		var fam := Content.item_family(id) if id != "heal" else ContentIds.PageIds.LEDGER
		var col := Pal.family_color(fam)
		var lift := -10.0 if i == sel else 0.0
		var r := Rect2(x0 + i * (cw + gap), 200 + lift, cw, ch)
		_rects.append(r)
		UI.panel(self, r, col)
		if i == sel:
			draw_rect(r.grow(4), Color(col, 0.8), false, 2.5)
		UI.text(self, r.position + Vector2(20, 36), UI.kind_label(id).to_upper(), 12, col, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
		UI.wrapped(self, r.position + Vector2(20, 70), UI.item_name(id), 24, Pal.INK, cw - 40, 2)
		_icon(r.position + Vector2(cw - 44, 46), id, col)
		draw_line(r.position + Vector2(20, 120), r.position + Vector2(cw - 20, 120), Color(Pal.INK, 0.15), 1.0)
		UI.wrapped(self, r.position + Vector2(20, 148), UI.item_desc(id), 16, Pal.INK_SOFT, cw - 40, 8)
		if prices.has(id):
			UI.text(self, r.position + Vector2(cw * 0.5, ch - 20), "%d ♯" % prices[id], 18, Pal.GOLD, HORIZONTAL_ALIGNMENT_CENTER, -1, true)
		var fc := Game.family_counts() if Game.has_run() else {}
		if Content.RUNES.has(id) and Content.RUNES[id].kind == "family" and fc.has(fam):
			UI.text(self, r.position + Vector2(20, ch - 20), "%s set: %d → %d" % [fam.capitalize(), fc[fam], fc[fam] + 1], 13, col)
	if allow_skip:
		var sr := Rect2(cx - 90, 200 + ch + 30, 180, 40)
		_rects.append(sr)
		draw_rect(sr, Color(Pal.PAPER, 0.9 if sel == n else 0.6))
		draw_rect(sr, Color(Pal.INK, 0.6 if sel == n else 0.2), false, 1.5)
		UI.text(self, Vector2(cx, sr.position.y + 27), "Leave them", 17, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)


func _icon(c: Vector2, id: String, col: Color) -> void:
	if Content.POWERS.has(id):
		Glyph.clef(self, Content.POWERS[id].family if Content.POWERS[id].family != "margin" else "wind", c, 12.0, col, 2.5)
	elif Content.RUNES.has(id):
		var pts := PackedVector2Array([c + Vector2(0, -16), c + Vector2(14, -4), c + Vector2(9, 14), c + Vector2(-9, 14), c + Vector2(-14, -4)])
		draw_colored_polygon(pts, Pal.PAPER_DARK)
		pts.append(pts[0])
		draw_polyline(pts, col, 2.5, true)
	else:
		Glyph.head(self, c + Vector2(-2, 8), 9.0, true, col)
		draw_line(c + Vector2(9, 5), c + Vector2(9, -20), col, 2.5)
