extends Overlay
## Your note's whole kit: powers, rune slots, the rune bag, permanent and margin runes,
## relics, and which family sets (and dissonances) are awake. Runes can only be swapped
## outside combat.

var sel := 0
var _rows: Array = []   # [{id, kind: "bag"/"info"}]
var _rects: Array = []


func _ready() -> void:
	super._ready()
	_rebuild()


func _rebuild() -> void:
	_rows.clear()
	for id in Game.run.runes_owned:
		_rows.append({"id": id, "kind": "bag"})
	for p in Game.run.powers:
		if not p.is_empty():
			_rows.append({"id": p.id, "kind": "info"})
	for id in Game.run.permanent:
		_rows.append({"id": id, "kind": "info"})
	for id in Game.run.relics:
		_rows.append({"id": id, "kind": "info"})
	sel = clampi(sel, 0, maxi(0, _rows.size() - 1))


func _locked() -> bool:
	return room != null and room.combat_active()


func handle_input() -> void:
	if cancel() or pressed("loadout"):
		close()
		return
	if _rows.is_empty():
		return
	if up():
		sel = (sel - 1 + _rows.size()) % _rows.size()
	elif down():
		sel = (sel + 1) % _rows.size()
	elif confirm():
		_toggle(sel)


func _gui_input(event: InputEvent) -> void:
	if _grace > 0.0:
		return
	if event is InputEventMouseMotion:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
				_toggle(k)


func _toggle(k: int) -> void:
	var row: Dictionary = _rows[k]
	if row.kind != "bag":
		return
	if _locked():
		Synth.sfx_play("error", -8.0)
		return
	var slots: Array = Game.run.rune_slots
	var at := slots.find(row.id)
	if at != -1:
		slots[at] = ""
	else:
		var empty := slots.find("")
		if empty == -1:
			Synth.sfx_play("error", -8.0)
			return
		slots[empty] = row.id
	Synth.sfx_play("tick", -6.0, 3.0)
	Game.mark_dirty()
	if room and room.player:
		room.player.refresh_stats()


func _draw() -> void:
	UI.dim(self, size, 0.5)
	var r := Rect2(60, 50, size.x - 120, size.y - 100)
	UI.panel(self, r, Pal.INK)
	var c := Content.character(Game.run.char)
	UI.text(self, r.position + Vector2(30, 44), "%s (%s)" % [c.name, c.role], 26, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, r.position + Vector2(30, 70), c.innate, 15, Pal.INK_SOFT)
	var s := Game.stats()
	var line := "HP %d   ·   damage +%d%%   ·   speed +%d%%   ·   cooldowns -%d%%   ·   beat window ±%d ms" % [
		int(s.max_hp), int(s.dmg * 100), int(s.speed * 100), int(s.cdr * 100), int(s.beat_window * 1000)]
	UI.text(self, r.position + Vector2(30, 96), line, 14, Pal.INK_SOFT)
	# Rhythm combos (issue #11): what to play, written as notes.
	var combos: ComboSet = Player.COMBO_SETS.get(Game.run.char)
	if combos:
		var parts: Array[String] = []
		for pattern in combos.patterns:
			parts.append("%s  %s" % [pattern.pattern_name, pattern.notation])
		UI.text(self, Vector2(r.end.x - 30, r.position.y + 44), "Combos:  " + "     ".join(parts), 14, Pal.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

	# Rune slots.
	var slots: Array = Game.run.rune_slots
	var sx := r.position.x + 30
	var sy := r.position.y + 124
	UI.text(self, Vector2(sx, sy), "RUNE SLOTS" + ("   (locked during combat)" if _locked() else ""), 12, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	for k in slots.size():
		var rr := Rect2(sx + k * 170, sy + 10, 160, 46)
		draw_rect(rr, Pal.PAPER_DARK if slots[k] != "" else Color(Pal.PAPER_DARK, 0.4))
		draw_rect(rr, Color(Pal.INK, 0.3), false, 1.0)
		if slots[k] != "":
			var fam := Content.item_family(slots[k])
			draw_rect(Rect2(rr.position, Vector2(4, rr.size.y)), Pal.family_color(fam))
			UI.text(self, rr.position + Vector2(14, 29), Content.item(slots[k]).name, 16, Pal.INK)
		else:
			UI.text(self, rr.position + Vector2(14, 29), "empty", 15, Pal.INK_FAINT)

	# Sets and dissonance.
	var fy := sy + 84
	var fc := Game.family_counts()
	var fx := sx
	for fam in fc:
		var col := Pal.family_color(fam)
		var n: int = fc[fam]
		UI.text(self, Vector2(fx, fy), "%s %d/3" % [fam.capitalize(), n], 15, col if n >= 2 else Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, -1, n >= 2)
		fx += 150
	var dis := Game.dissonances()
	if dis.size() > 0:
		var names: Array = []
		for d in dis:
			names.append(Content.DISSONANCE[d].name)
		UI.text(self, Vector2(fx + 20, fy), "Dissonance: " + ", ".join(names), 15, Pal.MARGIN, HORIZONTAL_ALIGNMENT_LEFT, -1, true)

	# The list.
	var ly := fy + 30
	_rects.clear()
	var col_w := 420.0
	for k in _rows.size():
		var row: Dictionary = _rows[k]
		var rr := Rect2(sx, ly + k * 30, col_w, 28)
		if rr.end.y > r.end.y - 10:
			break
		_rects.append(rr)
		if k == sel:
			draw_rect(rr, Color(Pal.GOLD, 0.15))
		var id: String = row.id
		var col := Pal.family_color(Content.item_family(id))
		draw_rect(Rect2(rr.position, Vector2(4, 28)), col)
		var mark := ""
		if row.kind == "bag":
			mark = "◆ " if slots.has(id) else "◇ "
		UI.text(self, rr.position + Vector2(14, 20), mark + UI.item_name(id), 16, Pal.INK)
		UI.text(self, rr.position + Vector2(col_w - 8, 20), UI.kind_label(id), 12, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	if _rows.is_empty():
		UI.text(self, Vector2(sx, ly + 20), "Nothing yet.", 16, Pal.INK_SOFT)

	# Description of the selection.
	if sel < _rows.size():
		var id: String = _rows[sel].id
		var dx := sx + col_w + 40
		var dw := r.end.x - dx - 30
		UI.text(self, Vector2(dx, ly + 20), UI.item_name(id), 24, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
		UI.text(self, Vector2(dx, ly + 44), UI.kind_label(id), 13, Pal.family_color(Content.item_family(id)), HORIZONTAL_ALIGNMENT_LEFT, -1, true)
		UI.wrapped(self, Vector2(dx, ly + 76), UI.item_desc(id), 17, Pal.INK_SOFT, dw, 8)
		if _rows[sel].kind == "bag":
			UI.text(self, Vector2(dx, ly + 250), "Press to equip / unequip.", 14, Pal.INK_SOFT)
		var fam := Content.item_family(id)
		if Content.FAMILY_SETS.has(fam):
			var sets: Dictionary = Content.FAMILY_SETS[fam]
			UI.text(self, Vector2(dx, ly + 290), "%s set" % fam.capitalize(), 14, Pal.family_color(fam), HORIZONTAL_ALIGNMENT_LEFT, -1, true)
			UI.wrapped(self, Vector2(dx, ly + 312), "2: " + sets[2].desc + "\n3: " + sets[3].desc, 15, Pal.INK_SOFT, dw, 4)
	UI.text(self, Vector2(r.end.x - 30, r.end.y - 16), "Tab / Esc to close", 13, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
