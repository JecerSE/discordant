extends Control
## Title: the Grand Score's night sky drifting past, the pixel logo, and our quarter note
## falling off it. The prologue (IntroCutscene) plays on first launch and from the menu.

const TUNING: CinematicTuning = preload("res://content/tuning/cinematic_tuning.tres")
const OPTIONS := ["Begin", "Prologue", "Settings", "Quit"]
const MENU_TOP := 392.0
const ROW := 50.0
const ROW_H := 42.0
const MENU_W := 300.0
const PANEL := Color(0.04, 0.04, 0.1, 0.55)
const CREAM := Color(0.95, 0.92, 0.85)
const SOFT := Color(0.72, 0.7, 0.8)

var sel := 0
## True when the prologue just ended on this screen's logo: no restart of the music.
var from_intro := false
var overlay: Node
var _t := 0.0
var _grace := 0.3
var _rects: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := EnvironmentBackdrop.new()
	backdrop.setup_area("grand", TUNING.title_drift)
	add_child(backdrop)
	if not from_intro:
		Synth.start_song(Content.PAGES["ledger"].song)
	Synth.hush = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _has_overlay():
		return
	if _grace > 0.0:
		_grace -= delta
		return
	var go := Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact")
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		sel = (sel - 1 + OPTIONS.size()) % OPTIONS.size()
		Synth.sfx_play("tick", -12.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		sel = (sel + 1) % OPTIONS.size()
		Synth.sfx_play("tick", -12.0)
	elif go:
		_pick(sel)


func _gui_input(event: InputEvent) -> void:
	if _has_overlay():
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
			Game.goto("intro")
		"Settings":
			var p := SettingsMenu.new()
			p.return_to_pause = false
			overlay = p
			add_child(p)
		"Quit":
			get_tree().quit()


func _draw() -> void:
	var sz := size
	TitleArt.falling_note(self, _t, sz)
	TitleArt.logo(self)
	TitleArt.subtitle(self)
	_rects.clear()
	var x := sz.x * 0.5 - MENU_W * 0.5
	draw_rect(Rect2(x - 12, MENU_TOP - 12, MENU_W + 24, OPTIONS.size() * ROW + 16), PANEL)
	for k in OPTIONS.size():
		var r := Rect2(x, MENU_TOP + k * ROW, MENU_W, ROW_H)
		_rects.append(r)
		if k == sel:
			draw_rect(r, Color(Pal.GOLD, 0.18))
			draw_rect(Rect2(r.position, Vector2(6, ROW_H)), Pal.GOLD)
			draw_rect(Rect2(r.end.x - 6, r.position.y, 6, ROW_H), Pal.GOLD)
		UI.text(self, Vector2(sz.x * 0.5, r.position.y + 29), OPTIONS[k], 22, CREAM if k == sel else SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	var m: Dictionary = Game.meta
	var stats := "climbs %d   ·   finished %d   ·   notes unlocked %d / 4" % [int(m.runs), int(m.wins), m.unlocked.size()]
	if int(m.get("secret_wins", 0)) > 0:
		stats += "   ·   coda ✓"
	UI.text(self, Vector2(sz.x * 0.5, sz.y - 32), stats, 15, SOFT, HORIZONTAL_ALIGNMENT_CENTER)


func _has_overlay() -> bool:
	for c in get_children():
		if c is Overlay:
			return true
	return false
