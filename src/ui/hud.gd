extends CanvasLayer
## Health, sharps, powers, the metronome, boss bar, announcements and toasts.

var room: Node
var prompt := ""
var canvas: Control
var _announce := {}
var _toasts: Array = []
var _flash := 0.0
var _flash_col := Pal.BLOOD
var _beat_pulse := 0.0
var _hit_pulse := 0.0


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)
	add_child(canvas)
	Beat.beat.connect(func(_n): _beat_pulse = 1.0)
	Game.toast.connect(_on_toast)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 2.5)
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 4.0)
	_hit_pulse = maxf(0.0, _hit_pulse - delta * 3.0)
	if not _announce.is_empty():
		_announce.t += delta
		if _announce.t > 3.2:
			_announce = {}
	for t in _toasts:
		t.t += delta
	_toasts = _toasts.filter(func(t): return t.t < 3.5)
	canvas.queue_redraw()


func announce(title: String, subtitle: String, col: Color) -> void:
	_announce = {"title": title, "sub": subtitle, "col": col, "t": 0.0}


func flash(col: Color) -> void:
	_flash = 0.5
	_flash_col = col


func beat_hit() -> void:
	_hit_pulse = 1.0


func _on_toast(text: String, col: Color) -> void:
	_toasts.append({"text": text, "col": col, "t": 0.0})


func _draw_hud() -> void:
	var size := canvas.size
	var ci := canvas
	if _flash > 0.0:
		for i in 6:
			var w := 40.0 - i * 6.0
			ci.draw_rect(Rect2(0, 0, size.x, w), Color(_flash_col, 0.06 * _flash))
			ci.draw_rect(Rect2(0, size.y - w, size.x, w), Color(_flash_col, 0.06 * _flash))
			ci.draw_rect(Rect2(0, 0, w, size.y), Color(_flash_col, 0.06 * _flash))
			ci.draw_rect(Rect2(size.x - w, 0, w, size.y), Color(_flash_col, 0.06 * _flash))

	var p = room.player if room else null
	if p and not Game.run.is_empty():
		_draw_health(ci, p)
		_draw_powers(ci, p, size)
	_draw_metronome(ci, size)
	_draw_boss(ci, size)
	_draw_status(ci, size)

	if prompt != "":
		var w := UI.text_width(prompt, 17) + 50.0
		var r := Rect2(size.x * 0.5 - w * 0.5, size.y - 128, w, 32)
		ci.draw_rect(r, Color(Pal.PAPER, 0.92))
		ci.draw_rect(r, Color(Pal.INK, 0.3), false, 1.0)
		UI.text(ci, Vector2(r.position.x + 12, r.position.y + 22), "E", 17, Pal.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
		UI.text(ci, Vector2(r.position.x + 34, r.position.y + 22), prompt, 17, Pal.INK)

	if not _announce.is_empty():
		var t: float = _announce.t
		var a := minf(1.0, t / 0.3) * minf(1.0, (3.2 - t) / 0.6)
		var col: Color = _announce.col
		UI.outlined(ci, Vector2(size.x * 0.5, size.y * 0.3), _announce.title, 46, Color(Pal.INK, a), Color(Pal.PAPER, a))
		var lw := UI.text_width(_announce.title, 46, true) * 0.6 * minf(1.0, t / 0.5)
		ci.draw_line(Vector2(size.x * 0.5 - lw, size.y * 0.3 + 14), Vector2(size.x * 0.5 + lw, size.y * 0.3 + 14), Color(col, a), 3.0)
		if _announce.sub != "":
			UI.outlined(ci, Vector2(size.x * 0.5, size.y * 0.3 + 46), _announce.sub, 20, Color(Pal.INK_SOFT, a), Color(Pal.PAPER, a), HORIZONTAL_ALIGNMENT_CENTER, false)

	var y := 120.0
	for t in _toasts:
		var a2 := minf(1.0, t.t / 0.2) * minf(1.0, (3.5 - t.t) / 0.5)
		var w2 := UI.text_width(t.text, 17) + 30.0
		var r2 := Rect2(size.x - w2 - 20, y, w2, 30)
		ci.draw_rect(r2, Color(Pal.PAPER, 0.9 * a2))
		ci.draw_rect(Rect2(r2.position, Vector2(4, 30)), Color(t.col, a2))
		UI.text(ci, r2.position + Vector2(16, 21), t.text, 17, Color(Pal.INK, a2))
		y += 36.0


func _draw_health(ci: CanvasItem, p: Node) -> void:
	var x := 24.0
	var y := 26.0
	Glyph.note(ci, p.char_id, Vector2(x + 16, y + 20), 1.0, 10.0, Pal.INK)
	var bw := 260.0
	var bx := x + 46.0
	var frac := clampf(p.hp / p.max_hp, 0.0, 1.0)
	# Health is a staff: five hairlines, filled in ink from the left.
	ci.draw_rect(Rect2(bx, y + 4, bw, 22), Color(Pal.PAPER, 0.85))
	ci.draw_rect(Rect2(bx, y + 4, bw * frac, 22), Pal.BLOOD.lerp(Pal.INK, 0.25))
	for i in 5:
		ci.draw_line(Vector2(bx, y + 4 + i * 5.5), Vector2(bx + bw, y + 4 + i * 5.5), Color(Pal.INK, 0.25), 1.0)
	ci.draw_rect(Rect2(bx, y + 4, bw, 22), Pal.INK, false, 1.5)
	UI.outlined(ci, Vector2(bx + bw * 0.5, y + 21), "%d / %d" % [int(ceil(p.hp)), int(p.max_hp)], 15, Pal.INK, Pal.PAPER)
	# Sharps.
	Glyph.sharp(ci, Vector2(bx + 8, y + 48), 9.0, Pal.GOLD)
	UI.text(ci, Vector2(bx + 22, y + 55), "%d" % int(Game.run.get("sharps", 0)), 20, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	var cx := bx + 90.0
	for fam in Game.run.get("clefs", []):
		Glyph.clef(ci, fam, Vector2(cx, y + 46), 9.0, Pal.MARGIN, 2.0)
		cx += 26.0
	if p.shield_hp > 0.0:
		UI.text(ci, Vector2(bx + bw + 10, y + 21), "+%d" % int(p.shield_hp), 15, Pal.STRING, HORIZONTAL_ALIGNMENT_LEFT, -1, true)


func _draw_powers(ci: CanvasItem, p: Node, size: Vector2) -> void:
	var keys := ["K", "L", "U"]
	var powers: Array = Game.run.get("powers", [])
	var x := 24.0
	var y := size.y - 84.0
	for i in powers.size():
		var r := Rect2(x, y, 64, 64)
		var pw: Dictionary = powers[i]
		ci.draw_rect(r, Color(Pal.PAPER, 0.9))
		if pw.is_empty():
			ci.draw_rect(r, Color(Pal.INK, 0.2), false, 1.5)
			UI.text(ci, Vector2(x + 32, y + 38), "-", 18, Pal.INK_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var d: Dictionary = Content.POWERS[pw.id]
			var col := Pal.family_color(d.family)
			ci.draw_rect(Rect2(x, y, 64, 5), col)
			var cd: float = p.cds[i]
			if cd > 0.0:
				var total := Powers.cooldown_of(pw.id, pw.get("lvl", 1))
				var k := clampf(cd / maxf(0.01, total), 0.0, 1.0)
				ci.draw_rect(Rect2(x, y + 64 * (1.0 - k), 64, 64 * k), Color(Pal.INK, 0.18))
			_power_icon(ci, pw.id, r.get_center() + Vector2(0, -4), col if cd <= 0.0 else Color(col, 0.45))
			ci.draw_rect(r, Color(Pal.INK, 0.5 if cd <= 0.0 else 0.25), false, 1.5)
			var lv: String = ["", "I", "II", "III"][clampi(pw.get("lvl", 1), 1, 3)]
			UI.text(ci, Vector2(x + 60, y + 60), lv, 12, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
			if cd > 0.0:
				UI.outlined(ci, Vector2(x + 32, y + 40), "%.1f" % cd, 15, Pal.INK, Pal.PAPER)
		UI.text(ci, Vector2(x + 5, y + 60), keys[i], 13, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
		if not pw.is_empty():
			UI.text(ci, Vector2(x + 32, y - 6), Content.POWERS[pw.id].name, 11, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		x += 74.0
	# Dash pip.
	var dk := clampf(p.dash_cd / 0.75, 0.0, 1.0)
	ci.draw_arc(Vector2(x + 14, y + 40), 11.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - dk), 20, Pal.INK if dk <= 0.0 else Pal.INK_SOFT, 3.0, true)
	UI.text(ci, Vector2(x + 14, y + 66), "dash", 11, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)


func _power_icon(ci: CanvasItem, id: String, c: Vector2, col: Color) -> void:
	var fam: String = Content.POWERS[id].family
	match fam:
		"percussion":
			ci.draw_rect(Rect2(c + Vector2(-14, -4), Vector2(28, 14)), Color(col, 0.35))
			ci.draw_rect(Rect2(c + Vector2(-14, -4), Vector2(28, 14)), col, false, 2.0)
			ci.draw_line(c + Vector2(-8, -14), c + Vector2(4, -4), col, 2.5)
		"wind":
			for i in 3:
				ci.draw_arc(c + Vector2(-6 + i * 5, 0), 10.0 - i * 2.0, -0.9, 0.9, 10, col, 2.5, true)
		"string":
			for i in 3:
				ci.draw_line(c + Vector2(-8 + i * 8, -14), c + Vector2(-8 + i * 8, 14), col, 1.5)
			ci.draw_arc(c, 12.0, 0, TAU, 20, col, 2.0, true)
		_:
			Glyph.fermata(ci, c + Vector2(0, 6), 12.0, col)


## Four beats of the bar. The lit one is now; a gold ring flashes when you hit on the beat.
func _draw_metronome(ci: CanvasItem, size: Vector2) -> void:
	if not Beat.running:
		return
	var cx := size.x * 0.5
	var y := size.y - 44.0
	var b := Beat.beat_index() % 4
	for i in 4:
		var x := cx - 66.0 + i * 44.0
		var active := i == b
		var r := 7.0 + (5.0 * _beat_pulse if active else 0.0)
		if i == 0:
			r += 2.0
		ci.draw_circle(Vector2(x, y), r, Pal.INK if active else Color(Pal.INK, 0.2))
	# The needle sweeps between beats.
	var ph := Beat.phase()
	var sweep := cx - 66.0 + (b + ph) * 44.0
	ci.draw_line(Vector2(sweep, y - 16), Vector2(sweep, y + 16), Color(Pal.INK, 0.35), 2.0)
	if _hit_pulse > 0.0:
		ci.draw_arc(Vector2(cx, y), 96.0 + (1.0 - _hit_pulse) * 20.0, 0, TAU, 40, Color(Pal.GOLD, _hit_pulse), 3.0, true)
	UI.text(ci, Vector2(cx + 110, y + 6), "%d bpm" % int(Beat.bpm * Beat.tempo_scale), 13, Pal.INK_SOFT)


func _draw_boss(ci: CanvasItem, size: Vector2) -> void:
	if room == null or room.boss_node == null or not is_instance_valid(room.boss_node) or room.boss_node.dead:
		return
	var b = room.boss_node
	var w := 500.0
	var x := size.x * 0.5 - w * 0.5
	var y := 30.0
	UI.outlined(ci, Vector2(size.x * 0.5, y), b.ename, 22, Pal.INK, Pal.PAPER)
	var frac := clampf(b.hp / b.max_hp, 0.0, 1.0)
	var col := Pal.family_color(b.family)
	ci.draw_rect(Rect2(x, y + 10, w, 12), Color(Pal.PAPER, 0.85))
	ci.draw_rect(Rect2(x, y + 10, w * frac, 12), col)
	ci.draw_rect(Rect2(x, y + 10, w, 12), Pal.INK, false, 1.5)
	for ph in b.phase_marks():
		ci.draw_line(Vector2(x + w * ph, y + 6), Vector2(x + w * ph, y + 26), Pal.INK, 2.0)


func _draw_status(ci: CanvasItem, size: Vector2) -> void:
	if room == null:
		return
	var page: Dictionary = Content.PAGES[room.page_id]
	var t: String = page.name
	UI.text(ci, Vector2(size.x - 24, 34), t, 18, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	if room.state == "fight" and room.type != "boss":
		var n: int = room.alive_enemies().size() + room.pending_spawns
		var waves_left: int = room.waves.size() - room.wave_i - 1
		var s := "%d rest%s remain" % [n, "" if n == 1 else "s"]
		if waves_left > 0:
			s += "  ·  %d more wave%s" % [waves_left, "" if waves_left == 1 else "s"]
		UI.text(ci, Vector2(size.x - 24, 58), s, 15, Pal.HUSH, HORIZONTAL_ALIGNMENT_RIGHT)
	elif room.state == "clear" and room.has_exit:
		UI.text(ci, Vector2(size.x - 24, 58), "exit is open  →", 15, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
	if room.type == "hub":
		UI.text(ci, Vector2(size.x - 24, 58), "walk right to start  →", 15, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT)
