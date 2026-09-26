extends Control
## Title: the Grand Score above, a quarter note falling off it.

var sel := 0
var _t := 0.0
var _grace := 0.3
var _rects: Array = []
var overlay: Node
var prologue := false
var _pro_i := 0
var _pro_t := 0.0

const OPTIONS := ["Begin", "Prologue", "Settings", "Quit"]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Synth.start_song(Content.PAGES["ledger"].song)
	Synth.hush = 0.0
	if not Game.meta.get("seen_prologue", false):
		prologue = true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _has_overlay():
		return
	if _grace > 0.0:
		_grace -= delta
		return
	var go := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact")
	if prologue:
		_pro_t += delta
		if go:
			if _pro_t * 45.0 < String(Content.PROLOGUE[_pro_i]).length():
				_pro_t = 99.0
			else:
				_pro_i += 1
				_pro_t = 0.0
				Synth.note("keys", 67 + _pro_i * 2, -12.0, false)
				if _pro_i >= Content.PROLOGUE.size():
					_end_prologue()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
			_end_prologue()
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		sel = (sel - 1 + OPTIONS.size()) % OPTIONS.size()
		Synth.sfx_play("tick", -12.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		sel = (sel + 1) % OPTIONS.size()
		Synth.sfx_play("tick", -12.0)
	elif go:
		_pick(sel)


func _end_prologue() -> void:
	prologue = false
	_pro_i = 0
	Game.meta.seen_prologue = true
	Game.save()
	_grace = 0.2


func _gui_input(event: InputEvent) -> void:
	if prologue or _has_overlay():
		return
	if event is InputEventMouseMotion:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				sel = k
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _grace <= 0.0:
		for k in _rects.size():
			if _rects[k].has_point(event.position):
				_pick(k)


func _pick(k: int) -> void:
	Synth.sfx_play("chime", -8.0)
	match OPTIONS[k]:
		"Begin":
			Game.goto("hub")
		"Prologue":
			prologue = true
			_pro_i = 0
			_pro_t = 0.0
		"Settings":
			var p := SettingsMenu.new()
			p.return_to_pause = false
			overlay = p
			add_child(p)
		"Quit":
			get_tree().quit()


func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), Pal.PAPER)
	# The Grand Score, drifting.
	var top := 120.0
	for i in 5:
		var y := top + i * 16.0
		var pts := PackedVector2Array()
		for k in 41:
			var x := sz.x * k / 40.0
			pts.append(Vector2(x, y + sin(x * 0.004 + _t * 0.6) * 10.0))
		draw_polyline(pts, Color(Pal.INK, 0.8), 1.5, true)
	for k in 9:
		var x := fmod(k * 173.0 + _t * 30.0, sz.x + 100.0) - 50.0
		var y := top + 8.0 * ((k * 3) % 9) + sin(x * 0.004 + _t * 0.6) * 10.0
		Glyph.head(self, Vector2(x, y), 7.0, k % 3 != 0, Color(Pal.INK, 0.7))
		draw_line(Vector2(x + 8, y - 2), Vector2(x + 8, y - 30), Color(Pal.INK, 0.7), 2.0)
	# Our quarter note, falling off it forever.
	var fall := fmod(_t * 0.35, 1.0)
	var fx := sz.x * 0.72 + sin(_t * 1.3) * 30.0
	var fy := lerpf(top + 60.0, sz.y + 60.0, fall)
	draw_set_transform(Vector2(fx, fy), sin(_t * 2.0) * 0.6, Vector2.ONE)
	Glyph.note(self, "quarter", Vector2.ZERO, 1.0, 16.0, Pal.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The margin line.
	draw_line(Vector2(90, 0), Vector2(90, sz.y), Color(Pal.MARGIN, 0.4), 2.0)

	UI.text(self, Vector2(160, 320), Content.TITLE, 72, Pal.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, true)
	UI.text(self, Vector2(166, 358), "a quarter note fell off the Grand Score", 22, Pal.INK_SOFT)

	if prologue:
		_draw_prologue(sz)
		return

	_rects.clear()
	for k in OPTIONS.size():
		var r := Rect2(160, 410 + k * 50, 280, 42)
		_rects.append(r)
		if k == sel:
			draw_rect(r, Color(Pal.GOLD, 0.15))
			draw_rect(Rect2(r.position, Vector2(4, 42)), Pal.GOLD)
		UI.text(self, r.position + Vector2(18, 29), OPTIONS[k], 22, Pal.INK)
	var m: Dictionary = Game.meta
	var stats := "climbs %d   ·   finished %d   ·   notes unlocked %d / 4" % [int(m.runs), int(m.wins), m.unlocked.size()]
	if int(m.get("secret_wins", 0)) > 0:
		stats += "   ·   coda ✓"
	UI.text(self, Vector2(166, sz.y - 40), stats, 15, Pal.INK_SOFT)


func _draw_prologue(sz: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, sz), Color(Pal.PAPER, 0.93))
	var line: String = Content.PROLOGUE[mini(_pro_i, Content.PROLOGUE.size() - 1)]
	var shown := int(_pro_t * 45.0)
	UI.wrapped(self, Vector2(sz.x * 0.5 - 380, sz.y * 0.42), line.substr(0, shown), 26, Pal.INK, 760, -1, HORIZONTAL_ALIGNMENT_CENTER)
	for k in Content.PROLOGUE.size():
		draw_circle(Vector2(sz.x * 0.5 - (Content.PROLOGUE.size() - 1) * 9.0 + k * 18.0, sz.y - 90), 4.0, Pal.INK if k <= _pro_i else Pal.INK_FAINT)
	UI.text(self, Vector2(sz.x * 0.5, sz.y - 50), "Space to continue  ·  Esc to skip", 14, Pal.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)


func _has_overlay() -> bool:
	for c in get_children():
		if c is Overlay:
			return true
	return false
